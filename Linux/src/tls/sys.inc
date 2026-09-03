default rel

%define SYS_read        0
%define SYS_write       1
%define SYS_open        2
%define SYS_close       3
%define SYS_poll        7
%define SYS_socket      41
%define SYS_connect     42
%define SYS_sendto      44
%define SYS_recvfrom    45
%define SYS_setsockopt  54
%define SYS_getsockopt  55
%define SYS_exit        60
%define SYS_fcntl       72

%define AF_INET         2
%define SOCK_STREAM     1
%define SOCK_DGRAM      2

%define SOL_SOCKET      1
%define SO_ERROR        4
%define SO_RCVTIMEO     20

%define F_GETFL         3
%define F_SETFL         4
%define O_NONBLOCK      0x800
%define O_RDONLY        0

%define POLLOUT         4
%define EINPROGRESS     115
