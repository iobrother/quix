-- --------------------------------------------------------
-- 主机:                           localhost
-- 服务器版本:                        5.7.41 - MySQL Community Server (GPL)
-- 服务器操作系统:                      Linux
-- HeidiSQL 版本:                  8.3.0.4694
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- 导出  表 quix.chat 结构
DROP TABLE IF EXISTS `chat`;
CREATE TABLE IF NOT EXISTS `chat` (
  `id` bigint(20) NOT NULL COMMENT '序号',
  `type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '消息类型',
  `channel_type` tinyint(3) NOT NULL DEFAULT '0' COMMENT '会话类型',
  `from` bigint(20) NOT NULL DEFAULT '0' COMMENT '发送者',
  `to` bigint(20) NOT NULL DEFAULT '0' COMMENT '接收者',
  `from_name` varchar(50) NOT NULL DEFAULT '' COMMENT '发送方名称',
  `from_avatar` varchar(100) NOT NULL DEFAULT '' COMMENT '发送方头像',
  `content` text COMMENT '内容',
  `send_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '发送时间',
  `read_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '读取时间',
  `flag` int(10) NOT NULL DEFAULT '0' COMMENT '标记',
  `language` int(10) NOT NULL COMMENT '语言',
  `name` varchar(32) NOT NULL DEFAULT '0' COMMENT '发送者名称',
  `extend` text COMMENT '扩展(以JSON格式存储)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='聊天记录表';

-- 数据导出被取消选择。


-- 导出  表 quix.coin_log 结构
DROP TABLE IF EXISTS `coin_log`;
CREATE TABLE IF NOT EXISTS `coin_log` (
  `id` bigint(20) NOT NULL COMMENT '系统编号',
  `uid` bigint(20) NOT NULL COMMENT '用户ID',
  `type` int(11) NOT NULL DEFAULT '0' COMMENT '变动类型',
  `before_coin` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动前金额',
  `after_coin` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动后金额',
  `amount` bigint(20) NOT NULL DEFAULT '0' COMMENT '变动数量',
  `game_id` int(11) NOT NULL DEFAULT '0' COMMENT '游戏ID',
  `created_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间',
  `remark` varchar(100) NOT NULL DEFAULT '' COMMENT '备注',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='余额变动明细';

-- 数据导出被取消选择。


-- 导出  表 quix.login_log 结构
DROP TABLE IF EXISTS `login_log`;
CREATE TABLE IF NOT EXISTS `login_log` (
  `id` bigint(20) NOT NULL COMMENT '系统编号',
  `uid` bigint(20) NOT NULL COMMENT '用户ID',
  `type` bigint(20) NOT NULL DEFAULT '0' COMMENT '登录方式 1:游客 2:手机验证码登录 3:账号密码登录 10:facebook 11:谷歌 12:apple',
  `platform` varchar(50) NOT NULL DEFAULT '' COMMENT '平台: PC_WEB android iOS H5',
  `app_version` varchar(50) NOT NULL DEFAULT '' COMMENT '主包版本',
  `res_version` varchar(50) NOT NULL DEFAULT '' COMMENT '资源版本',
  `device_id` varchar(50) NOT NULL DEFAULT '' COMMENT '设备ID',
  `device_name` varchar(50) NOT NULL DEFAULT '' COMMENT '设备名称',
  `device_model` varchar(50) NOT NULL DEFAULT '' COMMENT '机型',
  `login_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '登录时间',
  `logout_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '登出时间',
  `duration` bigint(20) NOT NULL DEFAULT '0' COMMENT '在线时长',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='登录日志';

-- 数据导出被取消选择。


-- 导出  表 quix.player 结构
DROP TABLE IF EXISTS `player`;
CREATE TABLE IF NOT EXISTS `player` (
  `uid` bigint(20) NOT NULL COMMENT '玩家ID',
  `name` varchar(50) NOT NULL DEFAULT '' COMMENT '角色名称',
  `rtime` bigint(20) NOT NULL DEFAULT '0' COMMENT '注册时间',
  `level` bigint(20) NOT NULL DEFAULT '0' COMMENT '等级',
  `exp` bigint(20) NOT NULL DEFAULT '0' COMMENT '经验',
  `energy` bigint(20) NOT NULL DEFAULT '0' COMMENT '能量',
  `coin` bigint(20) NOT NULL DEFAULT '0' COMMENT '金币',
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='玩家基础数据表';

-- 数据导出被取消选择。


-- 导出  表 quix.player_crontab 结构
DROP TABLE IF EXISTS `player_crontab`;
CREATE TABLE IF NOT EXISTS `player_crontab` (
  `uid` bigint(20) NOT NULL,
  `data` varchar(4096) NOT NULL DEFAULT '',
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC COMMENT='玩家定时器事件表';

-- 数据导出被取消选择。


-- 导出  过程 quix.sp_init_player 结构
DROP PROCEDURE IF EXISTS `sp_init_player`;
DELIMITER //
CREATE DEFINER=`root`@`%localhost` PROCEDURE `sp_init_player`(IN `p_id` BIGINT
)
BEGIN
	DECLARE is_new INT DEFAULT 0;
	DECLARE user_id BIGINT DEFAULT 0;
	SELECT `uid` INTO user_id FROM `player` WHERE `uid` = p_id LIMIT 1;
	IF FOUND_ROWS() = 0 THEN
		INSERT INTO `player`(`uid`, `name`, `rtime`) VALUES(p_id, CONCAT(p_id, ''), UNIX_TIMESTAMP(NOW()));
		SET is_new = 1;
	END IF;
	
	SELECT `uid` INTO user_id FROM `player_crontab` WHERE `uid` = p_id LIMIT 1;
	if FOUND_ROWS() = 0 THEN INSERT INTO `player_crontab`(`uid`) VALUES(p_id); END IF;
	
	SELECT is_new;
END//
DELIMITER ;


-- 导出  表 quix.user 结构
DROP TABLE IF EXISTS `user`;
CREATE TABLE IF NOT EXISTS `user` (
  `uid` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `mobile` varchar(50) NOT NULL DEFAULT '' COMMENT '手机',
  `email` varchar(50) NOT NULL DEFAULT '' COMMENT '邮箱',
  `password` varchar(50) NOT NULL DEFAULT '' COMMENT '密码',
  `created_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- 数据导出被取消选择。


-- 导出  表 quix.user_bind 结构
DROP TABLE IF EXISTS `user_bind`;
CREATE TABLE IF NOT EXISTS `user_bind` (
  `id` bigint(20) NOT NULL COMMENT '系统编号',
  `platform` tinyint(4) NOT NULL DEFAULT '0' COMMENT '平台1:guest 2:wx 3:apple 4:fb',
  `uid` bigint(20) NOT NULL COMMENT '用户ID',
  `unionid` varchar(50) NOT NULL DEFAULT '' COMMENT '微信unionid',
  `openid` varchar(50) NOT NULL DEFAULT '' COMMENT '第三方平台openid',
  `created_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='第三方账号绑定信息';

-- 数据导出被取消选择。
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
