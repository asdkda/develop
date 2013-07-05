
typedef struct _interface interface;

interface *new_interface(const char *text);
void fini_interface(interface *entry);
void interface_print(const interface *entry);


