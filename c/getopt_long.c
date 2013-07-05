#include <stdio.h>
#include <ctype.h>
#include <getopt.h> 

int main(int argc, char **argv)
{
	struct option long_options[] =
	{
			{"add", 1, 0, 0},
			{"append", 0, 0, 0},
			{"delete", 1, 0, 0},
			{"create", 1, 0, 'k'},	/* 返回k */
			{"file", 1, 0, 0},
			{0, 0, 0, 0}
	};
	int option_index = 0;
	int c;

	while (1)
	{
		c = getopt_long (argc, argv, "abc:d:", long_options, &option_index);

		/* Detect the end of the options. */
		if (c == -1)
		{
			for (; optind < argc; optind++)
			{
				unsigned char *c = (unsigned char *)argv[optind];
				for (; *c != 0; c++)
					if (!isspace(*c))
					{
						printf("junk found in command line, %s\n", argv[optind]);
						return -1;
					}
			}
			break;
		}

		switch (c)
		{
			case 0:
				printf ("option %s", long_options[option_index].name);
				if (optarg)
					printf (" with arg %s\n", optarg);
				else
					printf ("\n");
				break;

			case 'a':
				puts ("option -a\n");
				break;

			case 'b':
				puts ("option -b\n");
				break;

			case 'c':
				printf ("option -c with value `%s'\n", optarg);
				break;

			case 'd':
				printf ("option -d with value `%s'\n", optarg);
				break;

			case 'k':
				printf ("option --create with value `%s'\n", optarg);
				break;
		}
	}

	return 0;
}
