#!/bin/sh

#####################
# nginx configuration generator
#
# exit code:
# 0 success
# 1 interface not asigned ip address
# 2 nginx port overflow
#
######################


NGINX_DOC_ROOT=/data

NGINX_BIND_INTERFACE="br-lan"

NGINX_BIND_PORT_DEFAULT="8800"

NGINX_USER=root

XCTL_UNIX_PATH=unix:/tmp/nginx/socket/xctl.sock
MPS_UNIX_PATH=unix:/tmp/nginx/socket/mps.sock
RCMD_UNIX_PATH=unix:/tmp/nginx/socket/rcmd.sock
XLOGD_UNIX_PATH=unix:/tmp/nginx/socket/xlogd.sock

mkdir -p /tmp/nginx/logs
mkdir -p /tmp/nginx/conf
mkdir -p /tmp/nginx/socket

NGINX_CONF=/tmp/nginx/conf/nginx.conf
NGINX_PORT_FILE=/tmp/nginx/conf/nginx.port
NGINX_IP=""
NGINX_PORT=""

NGINX_LISTEN_STR=""

nginx_proxy_port_get()
{   
    local interface=${NGINX_BIND_INTERFACE}
    
	local nginx_port_old=""
	if [ -e ${NGINX_PORT_FILE} ]; then
		nginx_port_old=`cat ${NGINX_PORT_FILE}`
	fi

    local current_bind=`netstat -ntl | awk '{ print $4 }' | awk -F: '/:/{ print $2 }'`
    
    local port=${NGINX_BIND_PORT_DEFAULT}
    while [ ${port} -lt 65535 ]; do
        local is_in=`echo ${current_bind} | grep "^port$"`
        if [ "$is_in" == "" ]; then
            NGINX_PORT=${port}
            break
        fi
        port=`expr $port + 123`
    done
    
    if [ ${NGINX_PORT} -ge 65535 ]; then
        xlogger "nginx: nginx bind port overflow"
        exit 2 # port overflow
    fi
    
    xlogger "nginx: nginx listen on ${NGINX_PORT}"
 	echo -n "${NGINX_PORT}" > /tmp/nginx/conf/nginx.port   
   
	rm -f /tmp/nginx/conf/nginx.ip

    local ip=`ifconfig ${interface} | grep "inet " | awk -F: '{ print $2 }' | awk '{ print $1 }'`
    
    if [ "${ip}" == "" ]; then
        xlogger "nginx: interface ${interface} not asigned IP address"
		exit 3 # not ip
    else
        NGINX_IP=${ip}
        xlogger "nginx: interface ${interface} IP address ${NGINX_IP}"
        echo -n "${NGINX_IP}" > /tmp/nginx/conf/nginx.ip
        
        NGINX_LISTEN_STR="        listen       ${NGINX_IP}:${NGINX_PORT};"
    fi
    
	if [ "${nginx_port_old}" != "${NGINX_PORT}" ]; then
		# reload the xldp and racd
		xlogger "nginx: the nginx port is changed, restart the related module"
		/etc/init.d/appmsh stop
		/etc/init.d/xldpsh restart
		/etc/init.d/racdsh restart
		/etc/init.d/appmsh start
	fi
}

nginx_proxy_port_get

# generate head
cat << END > ${NGINX_CONF}
user ${NGINX_USER};
worker_processes  2;
error_log  /tmp/nginx/logs/error.log debug; 
pid        /tmp/nginx/logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/conf/mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  0;
    gzip  off;
    
	proxy_max_temp_file_size 0;
	proxy_request_buffering off;
	proxy_buffering off;
	proxy_buffer_size 4k;
	client_body_buffer_size 4k;

    server {
        ${NGINX_LISTEN_STR}
        listen       127.0.0.1:${NGINX_PORT};
        access_log off;
        
        location ${NGINX_DOC_ROOT} {
            root   /;
        }
        
        location /tmp/etm {
            root   /;
        }

        location /dlna.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${XCTL_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }
        
        location /protocol.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
        
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }
        
        location /upload.csp {
            client_max_body_size 0;
            
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }
        
        location /factory_reset.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }
        
        location /jsq.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
        
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }
        
        location /upgrade.do {
            proxy_pass http://${MPS_UNIX_PATH};
        }

        location /xlog.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${XLOGD_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }


      location /upgrade.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }


      location /diag.csp {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }

     location /factory_reset.do {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }

	location /remote_cmd {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${RCMD_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }

       location /reject_hdisk.do {
            add_header access-control-allow-credentials yes;
            add_header access-control-allow-headers X-Requested-With,Content-Type;
            add_header access-control-allow-methods GET,POST,OPTIONS;
            add_header access-control-allow-origin http://pan.xzb.xunlei.com;
            add_header Cache-Control max-age=604800;
            
            proxy_pass http://${MPS_UNIX_PATH};
            
            proxy_hide_header access-control-allow-credentials;
            proxy_hide_header access-control-allow-headers;
            proxy_hide_header access-control-allow-methods;
            proxy_hide_header access-control-allow-origin;
            proxy_hide_header Cache-Control;
        }

    }
}

END

exit 0
