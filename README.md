busybox
+++++++
Busybox tek bir dosya halinde bulunan birçok araç seçine sahip olan bir programdır. Bu araçlar initramfs sisteminde ve sistem genelinde sıkça kullanılabilir. Busybox aşağıdaki gibi kullanılır.

.. code-block:: shell

	$ busybox [komut] (seçenekler)

Eğer busyboxu komut adı ile linklersek o komutu doğrudan çalıştırabiliriz.

.. code-block:: shell

	$ ln -s /bin/bash ./ash
	$ ./ash

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

Static olarak derlemiş olduğumuz busyboxu kullanarak milimal kök dizin oluşturabiliriz. Bunun için öncelikle boş bir dizin açıp içerisine busyboxu kopyalayalım.

.. code-block:: shell

	$ mkdir -p rootfs/bin
	$ cp -fp /bin/busybox-static rootfs/busybox

Şimdi **chroot** komutu ile içerisine girelim ve /bin içerisine kuralım.

.. code-block:: shell

	$ chroot rootfs /busybox --install -s /bin

Artık minimal sistemimize giriş yapabiliriz.

.. code-block:: shell

	$ chroot rootfs /bin/ash

**chroot** komutu ile bir klasör içerisine bir dağıtım(işletim sistemi) hazırlanabilir. 
Daha detaylı bilgi için **chroot** kullanımına bakınız.

Busybox ile Minimal Dağıtım Oluşturma
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Busybox tek bir ikili dosya olarak temel linux komutlarını içerisinde barındıran bir dosyadır.
Bu dosya ve kernel olduğu zaman sistemimiz açılıçacak temel komutları kullabileceğimiz bir linux elde etmiş oluruz.

Bunun için;

.. code-block:: shell

	distro/busybox
	distro/init

yapıyı oluşturmalıyız . Bunun  için aşağıdaki komutlar çalıştırılır.

.. code-block:: shell

	mkdir distro
	cd distro
	cp /bin/busybox ./busybox	
	ldd ./busybox	 
	özdevimli bir çalıştırılabilir değil

"özdevimli bir çalıştırılabilir değil" dinamik değil diyor yani static kısacası bir bağımlılığı yok demektir.
Eğer bağımlılığı olsaydı bağımlı olduğu dosyalarıda konumlarına göre kopyalamamız gerekmekteydi.

**touch init** #dosyasını oluştur
içeriğine

.. code-block:: shell

	#!busybox ash
	PATH=/bin
	/busybox mkdir /bin
	/busybox --install -s /bin
	/busybox ash
şeklinde düzenle kaydet.

**chomod +x init** komutu ile çalıştırılır yapılır.
Ardından **find ./ |cpio -H newc -o >initrd.img** komutu ile **initrd.img** dosyası oluşturulur.

Oluşturulan **initrd.img** dosyası çalışacak tty açacak(konsol elde etmiş olacağız). 
Aslında bu işlemi yapan şey busybox ikili dosyası.

Son aşamada oluşan yapı şu şekilde oluyor.

.. code-block:: shell

	distro/init
	distro/initrd.img
	distro/busybox

Bize sadece distro klasöründeki **initrd.img** dosyası daha sonra kullanmak üzere gerekli olacak.

Bir distro isosu için aşağıdaki gibi bir klasör yapısı elde etmemiz gerekmektedir.

.. code-block:: shell

	distro/iso/boot/vmlinuz
	distro/iso/boot/initrd.img
	distro/iso/boot/grub/grub.cfg yapısını oluşturmalıyız.

şimdi sırasıyla satır satır yapıyı oluşturalım

.. code-block:: shell

	mkdir iso
	mkdir iso/boot
	cp /boot/vmlinuz* iso/boot/vmlinuz  #sistemde kullandığım kerneli kopyaladım istenirde kernel derlenebilir.
	mv ./initrd.img iso/boot/initrd.img #daha önce oluşturduğumuz **initrd.img** dosyamızı taşıyoruz.
	mkdir iso/boot/grub*
	touch iso/boot/grub/grub.cfg  #dosyası oluşturulur ve içeriği aşağıdaki gibi düzenlenir ve kaydedilir.

.. code-block:: shell

	linux /boot/vmlinuz
	initrd /boot/initrd.img
	boot

Yukarıdaki üç satır **iso/boot/grub/grub.cfg** dosyasının içeri olacak şekilde ayarlanır.

**grub-mkrescue iso/ -o distro.iso** komutuyla iso doyamız oluşturulur.

Artık sistemi açabilen ve tty açıp bize suna bir yapı oluşturduk. 
Çalıştırmak için qemu kullanılabililir.

**qemu-system-x86_64 -cdrom distro.iso -m 1G** komutuyla çalıştırıp test edebiliriz.. 
Eğer hatasız yapılmışsa sistem açılacak ve tty açacaktır. Birçok komut rahatlıkla çalışan bir dağıtım oluşturmuş olduk.



Bağımlılığı Olmayan Minimal Dağıtım Tasarımı
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Busybox ile bir dağıtım oluşturma işlemini yaptığınızı varsayıyorum.
Bu aşamaya kadar başarılı bir şekilde yaptığınızı varsayarak aklınıza bir çok soru gelecektir.
Bu sorulardan birini ben sorayım sizin yerinize. Busybox yoksa elimizde ya da olmasını istemiyorum nasıl olacak dağıtım diyebilirsiniz.
Ufak değişiklikler olsada **busybox** distrosu hazırlarken yaptığımız aşamaların aynısı olacak.
Bu durumda initrd.img dosyasını yeniden yazmamız gerekmektedir.
Yukarıda initrd.img dosyası için aşağıdaki gibi bir init dosyası oluşturduğumuzu hatırlıyorsunuzdur.

.. code-block:: shell

	#!busybox ash
	PATH=/bin
	/busybox mkdir /bin
	/busybox --install -s /bin
	/busybox ash

Daha sonra ise;
**chomod +x init** komutu ile çalıştırılır yapılır.
Ardından **find ./ |cpio -H newc -o >initrd.img** komutu ile **initrd.img** dosyasını oluşturmuştuk.

Şimdi bu işlemleri biraz değiştirip **busybox** dosyası yerine bağımsız bir init ikili dosyasını yazalım ve derleyelim.
Bunun için;

.. code-block:: shell

	distro/init.c

yapıyı oluşturmalıyız . Bunun  için aşağıdaki komutlar çalıştırılır.

.. code-block:: shell

	mkdir distro
	cd distro
	nano init.c
		
Komutlarından sonra **init.c** dosya içeriği aşağıdaki gibi olmalıdır.

.. code-block:: shell

	#include<stdio.h>

	int main()
	{
	char data[30];
	while(1)
	{
	printf(">>");scanf("%s",data);
	printf("girilen bilgi: %s\n",data);
	}
	return 0;
	}

**init.c** dosyası sonsuz bir döngüde bilgi alıyor ve ekrana girilen bilgi diye tekrar yazdırılıyor.
Şimdi ise **static** olarak derleyelim. **Static** derleme hiç bir başka
dosyaya ihtiyaç duymadan çalışacağı anlamına gelmektedir.

**gcc init.c -o init -static** bu komutla static olarak derledik. 
	
.. code-block:: shell

	ldd ./init	 
	özdevimli bir çalıştırılabilir değil

"özdevimli bir çalıştırılabilir değil" dinamik değil diyor yani static kısacası bir bağımlılığı yok demektir.
Eğer bağımlılığı olsaydı bağımlı olduğu dosyalarıda konumlarına göre kopyalamamız gerekmekteydi.

Şimdi ise initrd.img dosyasını oluşturacak komutumuzu çalıştıralım.
**echo "init"|cpio -H newc -o >initrd.img** bu komutla **initrd.img** dosyasını oluşturduk.

Bize sadece distro klasöründeki **initrd.img** dosyası daha sonra kullanmak üzere gerekli olacak.

Bir distro isosu için aşağıdaki gibi bir klasör yapısı elde etmemiz gerekmektedir.

.. code-block:: shell

	distro/iso/boot/vmlinuz
	distro/iso/boot/initrd.img
	distro/iso/boot/grub/grub.cfg yapısını oluşturmalıyız.

şimdi sırasıyla satır satır yapıyı oluşturalım

.. code-block:: shell

	mkdir iso
	mkdir iso/boot
	cp /boot/vmlinuz* iso/boot/vmlinuz  #sistemde kullandığım kerneli kopyaladım istenirde kernel derlenebilir.
	mv ./initrd.img iso/boot/initrd.img #daha önce oluşturduğumuz **initrd.img** dosyamızı taşıyoruz.
	mkdir iso/boot/grub*
	touch iso/boot/grub/grub.cfg  #dosyası oluşturulur ve içeriği aşağıdaki gibi düzenlenir ve kaydedilir.

.. code-block:: shell

	linux /boot/vmlinuz
	initrd /boot/initrd.img
	boot

Yukarıdaki üç satır **iso/boot/grub/grub.cfg** dosyasının içeri olacak şekilde ayarlanır.

**grub-mkrescue iso/ -o distro.iso** komutuyla iso doyamız oluşturulur.

Artık sistemi açabilen ve tty açıp bize suna bir yapı oluşturduk. 
Çalıştırmak için qemu kullanılabililir.

**qemu-system-x86_64 -cdrom distro.iso -m 1G** komutuyla çalıştırıp test edebiliriz.. 
Eğer hatasız yapılmışsa sistem açılacak ve **init** ikili dosyamız çalışacaktır.
Bizden bilgi girmemizi ve daha sonra girdiğimiz bilgiyi ekrana yazan bir bağımsız dağıtım yapmış olduk.



