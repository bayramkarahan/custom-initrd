kmod Nedir? Nasıl Yazılır ve Kullanılır?
++++++++++++++++++++++++++++++++++++++++++++++++

Linux çekirdeği ile donanım arasındaki haberleşmeyi sağlayan kod parçalarıdır. Bu kod parçalarını kernele eklediğimizde kerneli tekrardan derlememiz gerekmektedir. Her eklenen koddan sonra kernel derleme, kod çıkarttığımzda kernel derlemek ciddi bir iş yükü ve karmaşa yaratacaktır.

Bu sorunların çözümü için modul vardır. moduller kernele istediğimiz kod parpalarını ekleme ya da çıkartma yapabiliyoruz. Bu işlemleri yaparken kenel derleme işlemi yapmamıza gerek yok.

Kernele modul yükleme kaldırma için kmod aracı kullanılmaktadır. kmaod aracı;

	.. code-block:: shell

		ln -s kmod /bin/depmod
		ln -s kmod /bin/insmod
		ln -s kmod /initrd/bin/lsmod
		ln -s kmod /bin/modinfo
		ln -s kmod /bin/modprobe
		ln -s kmod /bin/rmmod

şeklinde sembolik bağlarla yeni araçlar oluşturulmuştur.

**lsmod :** yüklü modulleri listeler

**insmod:** tek bir modul yükler

**rmmod:** tek bir modul siler

**modinfo:** modul hakkında bilgi alınır 

**modprobe:** insmod komutunun aynısı fakat daha işlevseldir. module ait bağımlı olduğu modülleride yüklemektedir. modprobe  modülü /lib/modules/ dizini altında aramaktadır.

**depmod:** /lib/modules dizinindeki modüllerin listesini günceller. Fakat başka bir dizinde ise basedir=konum şeklinde belirtmek gerekir. konum dizininde /lib/modules/** şeklinde kalsörler olmalıdır.

 

hello.c dosyamız
++++++++++++++++

	.. code-block:: shell

		#include <linux/module.h>
		#include <linux/kernel.h>
		#include <linux/init.h>
		MODULE_DESCRIPTION("Hello World examples");
		MODULE_LICENSE("GPL");
		MODULE_AUTHOR("Bayram");
		static int __init hello_init(void)
		{
		printk(KERN_INFO "Hello world!\n");
		return 0;
		}
		static void __exit hello_cleanup(void)
		{
		printk(KERN_INFO "remove module.\n");
		}
		module_init(hello_init);
		module_exit(hello_cleanup);


Makefile dosyamız
+++++++++++++++++

	.. code-block:: shell

		obj-m+=my_module.o
		all:
		    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
		clean:
		    make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

modülün derlenmesi ve eklenip kaldırılması
++++++++++++++++++++++++++++++++++++++++++

	.. code-block:: shell

		make

		insmod my_modul.ko // modül kernele eklendi.

		lsmod | grep my_modul //modül yüklendi mi kontrol ediliyor.

		rmmod my_modul // modül kernelden çıkartılıyor.

Not:
++++
dmesg ile log kısmında eklendiğinde Hello Word yazısını ve  kaldırıldığında modul ismini görebiliriz.

