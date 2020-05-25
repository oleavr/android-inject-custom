#include <frida-core.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/xattr.h>

int
main (int argc, char * argv[])
{
  int result = 0;
  const char * path = "/data/local/tmp/android-inject-example/agent.so";
  const char * context = "u:object_r:frida_file:s0";
  FridaInjector * injector;
  int pid;
  GError * error;
  guint id;

  frida_init ();

  if (argc != 2)
    goto bad_usage;

  pid = atoi (argv[1]);
  if (pid <= 0)
    goto bad_usage;

  frida_selinux_patch_policy ();

  if (setxattr (path, XATTR_NAME_SELINUX, context, strlen (context) + 1, 0) != 0)
    goto setxattr_failed;

  injector = frida_injector_new ();

  error = NULL;
  id = frida_injector_inject_library_file_sync (injector, pid, path, "example_agent_main", "example data", NULL, &error);
  if (error != NULL)
  {
    g_printerr ("%s\n", error->message);
    g_clear_error (&error);

    result = 1;
  }

  frida_injector_close_sync (injector, NULL, NULL);
  g_object_unref (injector);

  frida_deinit ();

  return result;

bad_usage:
  {
    g_printerr ("Usage: %s <pid>\n", argv[0]);
    frida_deinit ();
    return 1;
  }
setxattr_failed:
  {
    g_printerr ("Failed to set SELinux permissions\n");
    frida_deinit ();
    return 1;
  }
}
