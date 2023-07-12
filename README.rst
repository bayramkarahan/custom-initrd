initrd Nedir? Nasıl Hazırlanır?
+++++++++++++++++++++++++++++++
initrd (initial RAM disk), Linux işletim sistemlerinde kullanılan bir geçici dosya sistemidir. Bu dosya sistemi, işletim sistemi açılırken kullanılan bir köprü görevi görür ve gerçek kök dosya sistemine geçiş yapmadan önce gerekli olan modülleri ve dosyaları içerir.Ayrıca, sistem başlatıldığında kök dosya sistemine erişim sağlamadan önce gerekli olan dosyaları yüklemek için de kullanılabilir.

Ardından, initrd içine dahil etmek istediğimiz temel dosyaları ve dizinleri bağımlılıklarıyla kopyalamalıyız.Bu dosyalar, sistem başlatıldığında kullanılacak olan temel bileşenleri içermelidir. Örneğin, donanım sürücüleri, ağ ayarları veya diğer gereksinimleriniz olabilir. Bağımlılıklar için aşağıdaki script kullanılacaktır. Script lddscript.sh dosyası olarak kaydedip kullanabilirsiniz. **bash lddscript.sh /bin/ls /tmp/test** şeklinde kullandığımızda /tmp/test/ dizinine **ls** dosyasının konumunu ve bağımlılıklarını kopyalayacaktır.
    
    .. code-block:: shell

	#!/bin/bash
	#bash lddscript binaryPath binaryTarget
	if [ ${#} != 2 ]
	then
	    echo "usage $0 PATH_TO_BINARY target_folder"
	    exit 1
	fi

	path_to_binary="$1"
	target_folder="$2"

	# if we cannot find the the binary we have to abort
	if [ ! -f "${path_to_binary}" ]
	then
	    echo "The file '${path_to_binary}' was not found. Aborting!"
	    exit 1
	fi

	# copy the binary itself
	##echo "---> copy binary itself"
	##cp --parents -v "${path_to_binary}" "${target_folder}"

	# copy the library dependencies
	echo "---> copy libraries"
	ldd "${path_to_binary}" | awk -F'[> ]' '{print $(NF-1)}' | while read -r lib
	do
	    [ -f "$lib" ] && cp -v --parents "$lib" "${target_folder}"
	done

    
Gerekli olacak dosyalarımızın dizin yapısı ve konumu aşağıdaki gibi olmalıdır. Anlatım buna göre yapalacaktır. Örneğin S1 ifadesi satır 1 anlamında anlatımı kolaylaştımak için yazılmıştır. Aşağıdaki yapıyı oluşturmak için yapılması gerekenleri adım adım anlatılacaktır. 
    
    .. code-block:: shell
    
	S1- distro/initrd/bin/busybox				#dosya
	S2- distro/initrd/bin/kmod				#dosya
	S3- distro/initrd/bin/debmod				#dosya
	S4- distro/initrd/bin/insmod				#dosya
	S5- distro/initrd/bin/lsmod				#dosya
	S6- distro/initrd/bin/modprobe				#dosya
	S7- distro/initrd/bin/rmmod				#dosya
	S8- distro/initrd/bin/modinfo				#dosya
	S9- distro/initrd/lib/modules/$(uname -r)/moduller	#dizin
	S10- distro/initrd/bin/systemd-udevd			#dosya
	S11- distro/initrd/bin/udevadm				#dosya
	S12- distro/etc/udev/rules.d				#dizin
	S13- distro/lib/udev/rules.d				#dizin
	S14- distro/initrd/bin/init				#dosya
	S15- distro/iso/initrd.img				#dosya
	S16- distro/iso/vmlinuz					#dosya
	S17- distro/iso/grub/grub.cfg				#dosya
	
Dizin Yapısının oluşturulması
+++++++++++++++++++++++++++++
Aşağıdaki komutları çalıştırdığımızda dizin yapımız oluşacaktır.   
	.. code-block:: shell

		mkdir -p initrd
		mkdir -p initrd/bin/
		mkdir -p initrd/lib/
		ln -s lib initrd/lib64
		mkdir -p initrd/lib/modules/
		mkdir -p initrd/lib/modules/$(uname -r)
		mkdir -p initrd/lib/modules/$(uname -r)/moduller
		mkdir -p initrd/etc/udev/
		mkdir -p initrd/lib/udev/
		mkdir -p iso
		mkdir -p iso/boot
		mkdir -p iso/boot/grub

S1- distro/initrd/bin/busybox
+++++++++++++++++++++++++++++
busybox yazının devamında busybox nedir başlığı altında anlatılmıştır. Burada sisteme nasıl ekleneceği anlatılacaktır.
	
	.. code-block:: shell
	
		cp /usr/bin/busybox initrd/bin/busybox #sistemden busybox kopyalandı..
		lddscript.sh initrd/bin/busybox initrd/ #sistemden busybox bağımlılıkları initrd dizinimize kopyalar.

S2-S8 distro/initrd/bin/kmod
++++++++++++++++++++++++++++
kmod yazının devamında kmod nedir başlığı altında anlatılmıştır. Burada sisteme nasıl ekleneceği anlatılacaktır.
	
	.. code-block:: shell
	
		cp /usr/bin/kmod initrd/bin/kmod #sistemden kmod kopyalandı..
		lddscript.sh initrd/bin/kmod initrd/ #sistemden kmod kütüphaneleri kopyalandı..
		ln -s kmod initrd/bin/depmod	 #kmod sembolik link yapılarak depmod hazırlandı.
		ln -s kmod initrd/bin/insmod	 #kmod sembolik link yapılarak insmod hazırlandı.
		ln -s kmod initrd/bin/lsmod	 #kmod sembolik link yapılarak lsmod hazırlandı.
		ln -s kmod initrd/bin/modinfo	 #kmod sembolik link yapılarak modinfo hazırlandı.
		ln -s kmod initrd/bin/modprobe	 #kmod sembolik link yapılarak modprobe hazırlandı.
		ln -s kmod initrd/bin/rmmod	 #kmod sembolik link yapılarak rmmode hazırlandı.

S9- distro/initrd/lib/modules/$(uname -r)/moduller
++++++++++++++++++++++++++++++++++++++++++++++++++
Bu bölümde modüller hazırlanacak. Burada dikkat etmemiz gereken önemli bir nokta kullandığımız kernel versiyonu neyse **initrd/lib/modules/modules** altında oluşacak dizinimiz aynı olmalıdır. Bundan dolayı **initrd/lib/modules/$(uname -r)** şeklinde dizin oluşturulmuştur. Aşağıda kullandığımız 2. satırdaki **/sbin/depmod --all --basedir=initrd**, **initrd/lib/modules/$(uname -r)/moduller** altındaki modullerimizin indeksinin oluşturuyor.

	.. code-block:: shell
		
		#döngüyle istediğimiz moduller initrd sistemimize dahil ediliyor.
		for directory in {crypto,fs,lib} \
    			drivers/{block,ata,md,firewire} \
   			drivers/{scsi,message,pcmcia,virtio} \
    			drivers/usb/{host,storage}; 
    			do
    				#echo ${directory}
   				find /lib/modules/$(uname -r)/kernel/${directory}/ -type f \
        			-exec install {} initrd/lib/modules/$(uname -r)/moduller \;
			done
		/sbin/depmod --all --basedir=initrd	#modüllerin indeks dosyası oluşturuluyor
		
S9- distro/initrd/bin/systemd-udevd
+++++++++++++++++++++++++++++++++++
	
udev, Linux çekirdeği tarafından sağlanan bir altyapıdır ve donanım aygıtlarının dinamik olarak algılanmasını ve yönetilmesini sağlar. systemd-udevd ise udev'in bir bileşenidir ve donanım olaylarını işlemek için kullanılır. Daha detaylı bilgi için yazının devamında udev nedir konu başlığı altında anlatılmıştır. systemd için **/lib/systemd/systemd-udevd**, no systemd için **/sbin/udevd** kullanılır. Biz systemd için tasarladığımız için **/lib/systemd/systemd-udevd** kullanıyoruz.
	
	.. code-block:: shell

		cp /lib/systemd/systemd-udevd initrd/bin/systemd-udevd #sistemden kopyalandı..
		lddscript initrd/bin/systemd-udevd initrd/ #sistemden kütüphaneler kopyalandı..

S10- distro/initrd/bin/udevadm
++++++++++++++++++++++++++++++
udevadm, Linux işletim sistemlerinde kullanılan bir araçtır. Bu araç, udev (Linux çekirdeği tarafından sağlanan bir hizmet) ile etkileşim kurmamızı sağlar. udevadm, sistemdeki aygıtların yönetimini kolaylaştırmak için kullanılır.

udevadm komutu, birçok farklı parametreyle kullanılabilir. İşte bazı yaygın kullanımları:

**udevadm info:** Bu komut, belirli bir aygıt hakkında ayrıntılı bilgi sağlar. Örneğin, udevadm info -a -n /dev/sda komutunu kullanarak /dev/sda aygıtıyla ilgili ayrıntıları alabilirsiniz.

**udevadm monitor:*** Bu komut, sistemdeki aygıtlarla ilgili olayları izlemek için kullanılır. Örneğin, udevadm monitor --property komutunu kullanarak aygıtların bağlanma ve çıkarma olaylarını izleyebilirsiniz.

**udevadm trigger:*** Bu komut, udev kurallarını yeniden değerlendirmek ve aygıtları yeniden tanımak için kullanılır. Örneğin, udevadm trigger --subsystem-match=block komutunu kullanarak blok aygıtlarını yeniden tanımlayabilirsiniz.

**udevadm control:** Bu komut, udev hizmetini kontrol etmek için kullanılır. Örneğin, udevadm control --reload komutunu kullanarak udev kurallarını yeniden yükleyebilirsiniz.

Bu sadece bazı temel kullanımlardır ve udevadm'nin daha fazla özelliği vardır. Daha fazla bilgi için, man udevadm komutunu kullanarak udevadm'nin man sayfasını inceleyebilirsiniz.
**Not:** udevadm systemd ve no systemd için aynı kullanımdadır. İki sistem içinde geçerlidir.

	.. code-block:: shell

		cp /bin/udevadm initrd/bin/udevadm #sistemden udevadm kopyalandı..
		lddscript initrd/bin/udevadm initrd/ #sistemden kütüphaneler kopyalandı..

S12- distro/etc/udev/rules.d--S13- distro/lib/udev/rules.d
++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"rules" kelimesi, Linux işletim sistemi veya bir programda belirli bir davranışı tanımlayan ve yönlendiren kuralları ifade eder. Bu kurallar, sistem veya programın nasıl çalışacağını belirlemek için kullanılır ve genellikle yapılandırma dosyalarında veya betiklerde tanımlanır.

Linux'ta "rules" terimi, genellikle udev kuralları veya iptables kuralları gibi belirli bileşenlerle ilişkilendirilir.

udev kuralları, Linux çekirdeği tarafından sağlanan bir altyapıdır ve donanım aygıtlarının nasıl tanınacağını ve nasıl işleneceğini belirlemek için kullanılır. Örneğin, bir USB cihazı takıldığında, udev kuralları bu cihazın nasıl adlandırılacağını ve hangi sürücünün kullanılacağını belirleyebilir.

Örnek bir udev kuralı:

ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1234", ATTR{idProduct}=="5678", RUN+="/path/to/script.sh"

Bu kural, bir USB cihazı eklendiğinde çalışacak bir betik belirtir. Kural, cihazın üretici kimliği (idVendor) ve ürün kimliği (idProduct) gibi özelliklerini kontrol eder ve belirli bir eylem gerçekleştirir.

Aşağıda sisteme ait kurralar initrd sistemimize kopyalanmaktadır.

	.. code-block:: shell

		cp /etc/udev/rules.d -rf  initrd/etc/udev/
		cp /lib/udev/rules.d -rf  initrd/lib/udev/
		
S14- distro/initrd/bin/init
+++++++++++++++++++++++++++
kernel ilk olarak initrd.img dosyasını ram'e yükleyecek ve ardından **init** dosyasının arayacaktır. Bu dosya bir script dosyası veya binary bir dosya olabilir. Bu tasarımda script dosya olacaktır. İçeriği aşağıdaki gibi olacaktır. 

.. code-block:: shell

	cat > initrd/init << EOF
		#!/bin/busybox ash
		PATH=/bin
		/bin/busybox mkdir -p /bin
		/bin/busybox --install -s /bin
		#**********************************
		export PATH=/bin:/sbin:/usr/bin:/usr/sbin

		[ -d /dev ]  || mkdir -m 0755 /dev	#/dev dizini yoksa oluştur
		[ -d /root ] || mkdir -m 0700 /root	#/root dizini yoksa oluştur
		[ -d /sys ]  || mkdir /sys		#/sys dizini yoksa oluştur
		[ -d /proc ] || mkdir /proc		#/proc dizini yoksa oluştur
		mkdir -p /tmp /run			# /tmp ve /run dizinleri oluşturuluyor

		# sisteme dizinler bağlanıyor(yükleniyor)
		mount -t devtmpfs devtmpfs /dev
		mount -t proc proc /proc
		mount -t sysfs sysfs /sys
		mount -t tmpfs tmpfs /tmp

		systemd-udevd --daemon --resolve-names=never #modprobe yerine kullanılıyor
		udevadm trigger --type=subsystems --action=add
		udevadm trigger --type=devices --action=add
		udevadm settle || true
		
		mkdir -p disk		# /dev/sda1 diskini bağlamak için dizin oluşturuluyor	
		modprobe ext4		#ext4 modülü yükleniyor harici olarak yüklememiz gerekiyor
		mount /dev/sda1 disk 	#diski bağlayalım
		
		exec switch_root /disk /sbin/init	#sistemi initrd içindeki initten sda1 diskinde olan /sbin/init'e devrediyoruz.
		/bin/busybox ash	#eğer üst satırdaki devir işlemi olmazsa bu satır çalışacak ve tty açılacaktır.
	EOF
	chmod +x initrd/init #init dosyasına çalıştırma izni veriyoruz.
	cd initrd
	find |cpio -H newc -o >initrd.img # initrd.img dosyasını initrd dizinine oluşturacaktır.|
	cd ..	

Oluşturulan **initrd.img** dosyası çalışacak tty açacak(konsol elde etmiş olacağız. 
Aslında bu işlemi yapan şey busybox ikili dosyası.


S15- distro/iso/initrd.img - S16- distro/iso/vmlinuz 
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
initrd.img dosyası kernel(vmlinuz) ile birlikte kullanılan belleğe ilk yüklenen dosyadır. Bu dosyanın görevi sistemin kurulu olduğu diski tanımak için gereken modülleri yüklemek ve sistemi başlatmaktır. Bu dosya /boot/initrd.img-xxx konumunda yer alır. initrd.img dosyası üretmek için 

.. code-block:: shell

	cp /boot/vmlinuz-$(uname -r) iso/boot/vmlinuz  #sistemde kullandığım kerneli kopyaladım istenirde kernel derlenebilir.
	mv initrd/initrd.img iso/boot/initrd.img #daha önce oluşturduğumuz **initrd.img** dosyamızı taşıyoruz.

S17- distro/iso/grub/grub.cfg
+++++++++++++++++++++++++++++
grub menu dosyası oluşturuluyor.

.. code-block:: shell

	cat > iso/boot/grub/grub.cfg << EOF
	linux /boot/vmlinuz
	initrd /boot/initrd.img
	boot
	EOF

Yukarıdaki script **iso/boot/grub/grub.cfg** dosyasının içeriği olacak şekilde ayarlanır.

İso Dosyasının Oluşturulması
++++++++++++++++++++++++++++

.. code-block:: shell

	grub-mkrescue iso/ -o distro.iso #iso doyamız oluşturulur.

Artık sistemi açabilen ve tty açıp bize suna bir yapı oluşturduk. Çalıştırmak için qemu kullanılabililir.


**qemu-system-x86_64 -cdrom distro.iso -m 1G** komutuyla çalıştırıp test edebiliriz. 

busybox Nedir?
++++++++++++++
Busybox tek bir dosya halinde bulunan birçok araç seçine sahip olan bir programdır. Bu araçlar initramfs sisteminde ve sistem genelinde sıkça kullanılabilir. Busybox aşağıdaki gibi kullanılır. Örneğin, dosya listelemek için ls komutunu kullanmak isterseniz:

.. code-block:: shell

	$ busybox ls

Busyboxtaki tüm araçları sisteme sembolik bağ atmak için aşağıdaki gibi bir yol izlenebilir. Bu işlem var olan dosyaları sildiği için tehlikeli olabilir. Sistemin tasarımına uygun olarak yapılmalıdır.

.. code-block:: shell

	$ busybox --install -s /bin # -s parametresi sembolik bağ olarak kurmaya yarar.

Busybox **static** olarak derlenmediği sürece bir libc kütüphanesine ihtiyaç duyar. initramfs içerisinde kullanılacaksa içerisine libc dahil edilmelidir. Bir dosyanın static olarak derlenip derlenmediğini öğrenmek için aşağıdaki komut kullanılır.

.. code-block:: shell

	$ ldd /bin/busybox # static derlenmişse hata mesajı verir. Derlenmemişse bağımlılıklarını listeler.

Busybox derlemek için öncelikle **make defconfig** kullanılarak veya önceden oluşturduğumuz yapılandırma dosyasını atarak yapılandırma işlemi yapılır. Ardından eğer static derleme yapacaksak yapılandırma dosyasına müdahale edilir. Son olarak **make** komutu kullanarak derleme işlemi yapılır.

.. code-block:: shell

	$ make defconfig
	$ sed -i "s|.*CONFIG_STATIC_LIBGCC .*|CONFIG_STATIC_LIBGCC=y|" .config
	$ sed -i "s|.*CONFIG_STATIC .*|CONFIG_STATIC=y|" .config
	$ make

Derleme bittiğinde kaynak kodun bulunduğu dizinde busybox dosyamız oluşmuş olur.

Static olarak derlemiş olduğumuz busyboxu kullanarak milimal kök dizin oluşturabiliriz. Burada static yapı kallanılmayacaktır. 
Sistemdeki /bin/busybox kullanılacaktır. Eğer yoksa busybox sisteme yüklenmelidir.

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

udev Nedir? Niçin Kullanılır?
++++++++++++++++++++++++++++++
systemd-udevd, Linux sistemlerinde donanım aygıtlarının eşleştirilmesi ve yönetimi için kullanılan bir sistem hizmetidir. Bu hizmet, udev adı verilen bir alt sistem üzerinde çalışır ve donanım olaylarını izler, aygıt dosyalarını oluşturur ve aygıtların durumunu günceller.

udev, Linux çekirdeği tarafından sağlanan bir altyapıdır ve donanım aygıtlarının dinamik olarak algılanmasını ve yönetilmesini sağlar. systemd-udevd ise udev'in bir bileşenidir ve donanım olaylarını işlemek için kullanılır.

systemd-udevd, donanım olaylarını izler ve bu olaylara göre belirli eylemler gerçekleştirir. Örneğin, bir USB cihazı takıldığında veya çıkarıldığında, systemd-udevd bu olayı algılar ve ilgili aygıt dosyasını oluşturur veya kaldırır. Ayrıca, donanım aygıtlarının durumunu güncellemek için de kullanılır. Örneğin, bir ağ arabirimi devre dışı bırakıldığında, systemd-udevd bu durumu algılar ve ilgili aygıt dosyasını günceller.

systemd-udevd, Linux sistemlerinde donanım aygıtlarının dinamik olarak yönetilmesini sağlayarak sistem yöneticilerine büyük bir esneklik ve kolaylık sağlar. Bu hizmet, donanım aygıtlarının otomatik olarak algılanmasını ve yapılandırılmasını sağlar, böylece kullanıcılar yeni bir aygıt takıldığında veya çıkarıldığında manuel olarak müdahale etmek zorunda kalmazlar.

