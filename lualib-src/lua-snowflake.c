#include <lua.h>
#include <lauxlib.h>
#include <stdbool.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

#include <pthread.h>

// 生成的ID最大位数是53位
#define TIMESTAMP_BITS 36
#define NODE_ID_BITS 5
#define SEQUENCE_BITS 12
#define NODE_ID_SHIFT SEQUENCE_BITS
#define TIMESTAMP_SHIFT (NODE_ID_SHIFT + NODE_ID_BITS)

#define SEQUENCE_MASK ((1 << SEQUENCE_BITS) - 1)

// 2023-11-23T18:00:00Z
// 单位是0.1s
#define SNOWFLAKE_EPOCH 17007624000L


static bool initialized = false;

static pthread_mutex_t g_mutex;
static uint64_t g_start_time = 0;
static uint64_t g_elapsed_time = 0;
static uint16_t g_sequence = 0;
static uint16_t g_node_id = 0;

// 以0.1要作为一个时钟周期, 0.1秒钟单节点最多生成2^12=4k个序号, 1秒钟单节点最多生成40k个序号
// 单位是0.1s
static uint64_t get_snowflake_time() {
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) == -1) {
        int saved_errno = errno;
        fprintf(stderr, "opendir error: %s\n", strerror(saved_errno));
		exit(EXIT_FAILURE);
    }

    uint64_t t;
    t = ts.tv_sec * 10;
    t += ts.tv_nsec / 100000000;

    return t;
}

static int64_t current_elapsed_time() {
    return get_snowflake_time() - g_start_time;
}

static int lsnowflake_init(lua_State *L) {
    g_node_id = luaL_checkinteger(L, 1);
    if (g_node_id < 0x00 || g_node_id > 0x1f) {
        return luaL_error(L, "node_id must be an integer n where 0 ≤ n ≤ 0x1f");
    }

    if (pthread_mutex_init(&g_mutex, NULL) != 0) {
		int saved_errno = errno;
		fprintf(stderr, "pthread_mutex_init error: %s\n", strerror(saved_errno));
		exit(EXIT_FAILURE);
	}

    g_start_time = SNOWFLAKE_EPOCH;
    initialized = true;

    return 1;
}

static int lsnowflake_next_id(lua_State *L) {
    if (!initialized) {
        return luaL_error(L, "snowflake.init must be called first");
    }

    pthread_mutex_lock(&g_mutex);

    long current = current_elapsed_time();
    if (g_elapsed_time < current) {
        g_elapsed_time = current;
        g_sequence = 0;
    } else {
        g_sequence = (g_sequence + 1) & SEQUENCE_MASK;
        if (g_sequence == 0) {
            // 借用下一个周期来生成ID
            g_elapsed_time++;
        }
    }

    if (g_elapsed_time >= (uint64_t)1 << TIMESTAMP_BITS) {
        fprintf(stderr, "over the time limit\n");
        abort();
    }

    uint64_t id = (g_elapsed_time << TIMESTAMP_SHIFT) | (g_node_id << NODE_ID_SHIFT) | g_sequence;
    pthread_mutex_unlock(&g_mutex);
    lua_pushinteger(L, id);

    return 1;
}

LUAMOD_API int luaopen_snowflake_core(lua_State *L)
{
	luaL_checkversion(L);
	luaL_Reg l[] =
	{
		{ "init", lsnowflake_init },
		{ "next_id", lsnowflake_next_id },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);

	return 1;
}
