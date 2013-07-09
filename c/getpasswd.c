#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <shadow.h>

int
main(int argc, char *argv[])
{
	struct passwd pwd;
	struct passwd *result;
	char *buf;
	size_t bufsize;
	int s;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s username\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	bufsize = sysconf(_SC_GETPW_R_SIZE_MAX);
	if (bufsize == -1)          /* Value was indeterminate */
		bufsize = 16384;        /* Should be more than enough */

	buf = malloc(bufsize);
	if (buf == NULL) {
		perror("malloc");
		exit(EXIT_FAILURE);
	}

	s = getpwnam_r(argv[1], &pwd, buf, bufsize, &result);
	if (result == NULL) {
		if (s == 0)
			printf("Not found\n");
		else {
			errno = s;
			perror("getpwnam_r");
		}
		exit(EXIT_FAILURE);
	}

	printf("Name: %s; UID: %ld; ", pwd.pw_gecos, (long) pwd.pw_uid);

	struct spwd spw;
	struct spwd *resultsp = NULL;
	s = getspnam_r(argv[1], &spw, buf, bufsize, &resultsp);
	if (s || !resultsp)
	{
		perror("getspnam_r");
		printf("PASSWD: aa\n");
	}
	else
		printf("PASSWD: %s\n", resultsp->sp_pwdp);
	
	
	free(buf);
	
	exit(EXIT_SUCCESS);
}
