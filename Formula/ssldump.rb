require 'formula'

class Ssldump < Formula
  homepage 'http://www.rtfm.com/ssldump/'
  url 'https://downloads.sourceforge.net/project/ssldump/ssldump/0.9b3/ssldump-0.9b3.tar.gz?r=http%3A%2F%2Fssldump.sourceforge.net%2F&ts=1508313534&use_mirror=excellmedia'
  sha256 '6422c16718d27c270bbcfcc1272c4f9bd3c0799c351f1d6dd54fdc162afdab1e'

  depends_on 'openssl'

  # reorder include files
  # http://sourceforge.net/tracker/index.php?func=detail&aid=1622854&group_id=68993&atid=523055
  # increase pcap sample size from an arbitrary 5000 the max TLS packet size 18432
  # openssl compat: (extracted from http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=337453 )
  def patches
    DATA
  end

  def install
    ENV["LIBS"] = "-lssl -lcrypto"

    # .dylib, not .a
    #inreplace "configure", "if test -f $dir/libpcap.a; then",
                           #"if test -f $dir/libpcap.dylib; then"
	inreplace "configure", "libpcap.a", "libpcap.dylib"

    openssl = Formula.factory('openssl')

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--with-openssl=#{openssl.prefix}",
                          #"--with-pcap-lib=/usr/local/opt/libpcap/lib}",
                          #"--with-pcap-inc=/usr/local/opt/libpcap/include}",
                          "--with-pcap=/usr/local/opt/libpcap}",
                          "osx"
    system "make"
    bin.install "ssldump"
    man1.install "ssldump.1"
  end
end

__END__
diff -Naur a/base/pcap-snoop.c b/base/pcap-snoop.c
--- a/base/pcap-snoop.c	2002-09-10 01:02:58.000000000 +0400
+++ b/base/pcap-snoop.c	2017-10-18 12:40:18.000000000 +0400
@@ -46,10 +46,9 @@
 
 static char *RCSSTRING="$Id: pcap-snoop.c,v 1.14 2002/09/09 21:02:58 ekr Exp $";
 
-
+#include <net/bpf.h>
 #include <pcap.h>
 #include <unistd.h>
-#include <net/bpf.h>
 #ifndef _WIN32
 #include <sys/param.h>
 #endif
@@ -286,7 +285,7 @@
           err_exit("Aborting",-1);
         }
       }
-      if(!(p=pcap_open_live(interface_name,5000,!no_promiscuous,1000,errbuf))){
+      if(!(p=pcap_open_live(interface_name,18432,!no_promiscuous,1000,errbuf))){
 	fprintf(stderr,"PCAP: %s\n",errbuf);
 	err_exit("Aborting",-1);
       }
diff -Naur a/configure b/configure
--- a/configure	2001-11-27 02:38:13.000000000 +0400
+++ b/configure	2017-10-18 12:40:37.000000000 +0400
@@ -1103,7 +1103,7 @@
 echo "configure:1104: checking for PCAP library" >&5
 ac_found_pcap_lib_dir="no"
 for dir in $ac_pcap_lib_dir; do
-	if test -f $dir/libpcap.a; then
+	if test -f $dir/libpcap.dylib; then
 				save_LIBS=$LIBS
 		save_LDFLAGS=$LDFLAGS
 		LIBS="-lpcap $LIBS"
diff -Naur a/ssl/ssl.enums b/ssl/ssl.enums
--- a/ssl/ssl.enums	2001-07-20 20:44:32.000000000 +0400
+++ b/ssl/ssl.enums	2017-10-18 12:40:18.000000000 +0400
@@ -378,6 +378,141 @@
     CipherSuite	TLS_ECDH_ECDSA_WITH_DES_CBC_SHA  = {0x00,0x49};
     CipherSuite	TLS_ECDH_ECDSA_EXPORT_WITH_RC4_56_SHA={0xff,0x85};
     CipherSuite	TLS_ECDH_ECDSA_EXPORT_WITH_RC4_40_SHA={0xff,0x84};
+
+    /***** Patch additions from following URL *****/
+    /* https://github.com/jtapiath-cl/gokik/blob/0de0f3e7/Security.framework/Headers/CipherSuite.h */
+    /* TLS addenda using AES, per RFC 3268 */
+    CipherSuite	TLS_RSA_WITH_AES_128_CBC_SHA           ={0x00,0x2f};
+    CipherSuite	TLS_DH_DSS_WITH_AES_128_CBC_SHA        ={0x00,0x30};
+    CipherSuite	TLS_DH_RSA_WITH_AES_128_CBC_SHA        ={0x00,0x31};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_128_CBC_SHA       ={0x00,0x32};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_128_CBC_SHA       ={0x00,0x33};
+    CipherSuite	TLS_DH_anon_WITH_AES_128_CBC_SHA       ={0x00,0x34};
+    CipherSuite	TLS_RSA_WITH_AES_256_CBC_SHA           ={0x00,0x35};
+    CipherSuite	TLS_DH_DSS_WITH_AES_256_CBC_SHA        ={0x00,0x36};
+    CipherSuite	TLS_DH_RSA_WITH_AES_256_CBC_SHA        ={0x00,0x37};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_256_CBC_SHA       ={0x00,0x38};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_256_CBC_SHA       ={0x00,0x39};
+    CipherSuite	TLS_DH_anon_WITH_AES_256_CBC_SHA       ={0x00,0x3a};
+
+    /* ECDSA addenda, RFC 4492 */
+    CipherSuite	TLS_ECDH_ECDSA_WITH_NULL_SHA           ={0xc0,0x01};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_RC4_128_SHA        ={0xc0,0x02};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA   ={0xc0,0x03};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA    ={0xc0,0x04};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA    ={0xc0,0x05};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_NULL_SHA          ={0xc0,0x06};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_RC4_128_SHA       ={0xc0,0x07};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA  ={0xc0,0x08};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA   ={0xc0,0x09};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA   ={0xc0,0x0A};
+    CipherSuite	TLS_ECDH_RSA_WITH_NULL_SHA             ={0xc0,0x0B};
+    CipherSuite	TLS_ECDH_RSA_WITH_RC4_128_SHA          ={0xc0,0x0C};
+    CipherSuite	TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA     ={0xc0,0x0D};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_128_CBC_SHA      ={0xc0,0x0E};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_256_CBC_SHA      ={0xc0,0x0F};
+    CipherSuite	TLS_ECDHE_RSA_WITH_NULL_SHA            ={0xc0,0x10};
+    CipherSuite	TLS_ECDHE_RSA_WITH_RC4_128_SHA         ={0xc0,0x11};
+    CipherSuite	TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA    ={0xc0,0x12};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA     ={0xc0,0x13};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA     ={0xc0,0x14};
+    CipherSuite	TLS_ECDH_anon_WITH_NULL_SHA            ={0xc0,0x15};
+    CipherSuite	TLS_ECDH_anon_WITH_RC4_128_SHA         ={0xc0,0x16};
+    CipherSuite	TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA    ={0xc0,0x17};
+    CipherSuite	TLS_ECDH_anon_WITH_AES_128_CBC_SHA     ={0xc0,0x18};
+    CipherSuite	TLS_ECDH_anon_WITH_AES_256_CBC_SHA     ={0xc0,0x19};
+
+    /***** TLS 1.2 addenda, RFC 5246 *****/
+    /* Initial state. */
+    CipherSuite	TLS_NULL_WITH_NULL_NULL                ={0x00,0x00};
+
+    /* Server provided RSA certificate for key exchange. */
+    CipherSuite	TLS_RSA_WITH_NULL_MD5                     ={0x00,0x01};
+    CipherSuite	TLS_RSA_WITH_NULL_SHA                     ={0x00,0x02};
+    CipherSuite	TLS_RSA_WITH_RC4_128_MD5                  ={0x00,0x04};
+    CipherSuite	TLS_RSA_WITH_RC4_128_SHA                  ={0x00,0x05};
+    CipherSuite	TLS_RSA_WITH_3DES_EDE_CBC_SHA             ={0x00,0x0A};
+    //CipherSuite	TLS_RSA_WITH_AES_128_CBC_SHA            ={0x00,0x2F};
+    //CipherSuite	TLS_RSA_WITH_AES_256_CBC_SHA            ={0x00,0x35};
+    CipherSuite	TLS_RSA_WITH_NULL_SHA256                  ={0x00,0x3B};
+    CipherSuite	TLS_RSA_WITH_AES_128_CBC_SHA256           ={0x00,0x3C};
+    CipherSuite	TLS_RSA_WITH_AES_256_CBC_SHA256           ={0x00,0x3D};
+
+    /* Server-authenticated (and optionally client-authenticated) Diffie-Hellman. */
+    CipherSuite	TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA          ={0x00,0x0D};
+    CipherSuite	TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA          ={0x00,0x10};
+    CipherSuite	TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA         ={0x00,0x13};
+    CipherSuite	TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA         ={0x00,0x16};
+    //CipherSuite	TLS_DH_DSS_WITH_AES_128_CBC_SHA         ={0x00,0x30};
+    //CipherSuite	TLS_DH_RSA_WITH_AES_128_CBC_SHA         ={0x00,0x31};
+    //CipherSuite	TLS_DHE_DSS_WITH_AES_128_CBC_SHA        ={0x00,0x32};
+    //CipherSuite	TLS_DHE_RSA_WITH_AES_128_CBC_SHA        ={0x00,0x33};
+    //CipherSuite	TLS_DH_DSS_WITH_AES_256_CBC_SHA         ={0x00,0x36};
+    //CipherSuite	TLS_DH_RSA_WITH_AES_256_CBC_SHA         ={0x00,0x37};
+    //CipherSuite	TLS_DHE_DSS_WITH_AES_256_CBC_SHA        ={0x00,0x38};
+    //CipherSuite	TLS_DHE_RSA_WITH_AES_256_CBC_SHA        ={0x00,0x39};
+    CipherSuite	TLS_DH_DSS_WITH_AES_128_CBC_SHA256        ={0x00,0x3E};
+    CipherSuite	TLS_DH_RSA_WITH_AES_128_CBC_SHA256        ={0x00,0x3F};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_128_CBC_SHA256       ={0x00,0x40};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_128_CBC_SHA256       ={0x00,0x67};
+    CipherSuite	TLS_DH_DSS_WITH_AES_256_CBC_SHA256        ={0x00,0x68};
+    CipherSuite	TLS_DH_RSA_WITH_AES_256_CBC_SHA256        ={0x00,0x69};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_256_CBC_SHA256       ={0x00,0x6A};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_256_CBC_SHA256       ={0x00,0x6B};
+
+    /* Completely anonymous Diffie-Hellman */
+    CipherSuite	TLS_DH_anon_WITH_RC4_128_MD5              ={0x00,0x18};
+    CipherSuite	TLS_DH_anon_WITH_3DES_EDE_CBC_SHA         ={0x00,0x1B};
+    //CipherSuite	TLS_DH_anon_WITH_AES_128_CBC_SHA        ={0x00,0x34};
+    //CipherSuite	TLS_DH_anon_WITH_AES_256_CBC_SHA        ={0x00,0x3A};
+    CipherSuite	TLS_DH_anon_WITH_AES_128_CBC_SHA256       ={0x00,0x6C};
+    CipherSuite	TLS_DH_anon_WITH_AES_256_CBC_SHA256       ={0x00,0x6D};
+
+    /* Addenda from rfc 5288 AES Galois Counter Mode (GCM) Cipher Suites for TLS. */
+    CipherSuite	TLS_RSA_WITH_AES_128_GCM_SHA256           ={0x00,0x9C};
+    CipherSuite	TLS_RSA_WITH_AES_256_GCM_SHA384           ={0x00,0x9D};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_128_GCM_SHA256       ={0x00,0x9E};
+    CipherSuite	TLS_DHE_RSA_WITH_AES_256_GCM_SHA384       ={0x00,0x9F};
+    CipherSuite	TLS_DH_RSA_WITH_AES_128_GCM_SHA256        ={0x00,0xA0};
+    CipherSuite	TLS_DH_RSA_WITH_AES_256_GCM_SHA384        ={0x00,0xA1};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_128_GCM_SHA256       ={0x00,0xA2};
+    CipherSuite	TLS_DHE_DSS_WITH_AES_256_GCM_SHA384       ={0x00,0xA3};
+    CipherSuite	TLS_DH_DSS_WITH_AES_128_GCM_SHA256        ={0x00,0xA4};
+    CipherSuite	TLS_DH_DSS_WITH_AES_256_GCM_SHA384        ={0x00,0xA5};
+    CipherSuite	TLS_DH_anon_WITH_AES_128_GCM_SHA256       ={0x00,0xA6};
+    CipherSuite	TLS_DH_anon_WITH_AES_256_GCM_SHA384       ={0x00,0xA7};
+
+    /* Addenda from rfc 5289  Elliptic Curve Cipher Suites with HMAC SHA-256/384. */
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256   ={0xC0,0x23};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384   ={0xC0,0x24};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256    ={0xC0,0x25};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384    ={0xC0,0x26};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256     ={0xC0,0x27};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384     ={0xC0,0x28};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256      ={0xC0,0x29};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384      ={0xC0,0x2A};
+
+    /* Addenda from rfc 5289  Elliptic Curve Cipher Suites with SHA-256/384 and AES Galois Counter Mode (GCM) */
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256   ={0xC0,0x2B};
+    CipherSuite	TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384   ={0xC0,0x2C};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256    ={0xC0,0x2D};
+    CipherSuite	TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384    ={0xC0,0x2E};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256     ={0xC0,0x2F};
+    CipherSuite	TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384     ={0xC0,0x30};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256      ={0xC0,0x31};
+    CipherSuite	TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384      ={0xC0,0x32};
+
+    /* RFC 5746 - Secure Renegotiation */
+    CipherSuite	TLS_EMPTY_RENEGOTIATION_INFO_SCSV         ={0x00,0xFF};
+
+    /* Tags for SSL 2 cipher kinds which are not specified for SSL 3. */
+    CipherSuite	SSL_RSA_WITH_RC2_CBC_MD5                  ={0xFF,0x80};
+    CipherSuite	SSL_RSA_WITH_IDEA_CBC_MD5                 ={0xFF,0x81};
+    CipherSuite	SSL_RSA_WITH_DES_CBC_MD5                  ={0xFF,0x82};
+    CipherSuite	SSL_RSA_WITH_3DES_EDE_CBC_MD5             ={0xFF,0x83};
+    CipherSuite	SSL_NO_SUCH_CIPHERSUITE                   ={0xFF,0xFF};
+    /***** /Patch additions *****/
+
   } cipher_suite;  
 
     	   
diff -Naur a/ssl/ssl.enums.c b/ssl/ssl.enums.c
--- a/ssl/ssl.enums.c	2001-07-20 20:44:36.000000000 +0400
+++ b/ssl/ssl.enums.c	2017-10-18 12:40:18.000000000 +0400
@@ -698,6 +698,393 @@
 		65412,
 		"TLS_ECDH_ECDSA_EXPORT_WITH_RC4_40_SHA",
 		0	},
+	/***** Patch additions from following URL *****/
+	/* https://github.com/jtapiath-cl/gokik/blob/0de0f3e7/Security.framework/Headers/CipherSuite.h */
+	{
+		47,
+		"TLS_RSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		48,
+		"TLS_DH_DSS_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49,
+		"TLS_DH_RSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		50,
+		"TLS_DHE_DSS_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		51,
+		"TLS_DHE_RSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		52,
+		"TLS_DH_anon_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		53,
+		"TLS_RSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		54,
+		"TLS_DH_DSS_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		55,
+		"TLS_DH_RSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		56,
+		"TLS_DHE_DSS_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		57,
+		"TLS_DHE_RSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		58,
+		"TLS_DH_anon_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		49153,
+		"TLS_ECDH_ECDSA_WITH_NULL_SHA",
+		0	},
+	{
+		49154,
+		"TLS_ECDH_ECDSA_WITH_RC4_128_SHA",
+		0	},
+	{
+		49155,
+		"TLS_ECDH_ECDSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		49156,
+		"TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49157,
+		"TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		49158,
+		"TLS_ECDHE_ECDSA_WITH_NULL_SHA",
+		0	},
+	{
+		49159,
+		"TLS_ECDHE_ECDSA_WITH_RC4_128_SHA",
+		0	},
+	{
+		49160,
+		"TLS_ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		49161,
+		"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49162,
+		"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		49163,
+		"TLS_ECDH_RSA_WITH_NULL_SHA",
+		0	},
+	{
+		49164,
+		"TLS_ECDH_RSA_WITH_RC4_128_SHA",
+		0	},
+	{
+		49165,
+		"TLS_ECDH_RSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		49166,
+		"TLS_ECDH_RSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49167,
+		"TLS_ECDH_RSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		49168,
+		"TLS_ECDHE_RSA_WITH_NULL_SHA",
+		0	},
+	{
+		49169,
+		"TLS_ECDHE_RSA_WITH_RC4_128_SHA",
+		0	},
+	{
+		49170,
+		"TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		49171,
+		"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49172,
+		"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		49173,
+		"TLS_ECDH_anon_WITH_NULL_SHA",
+		0	},
+	{
+		49174,
+		"TLS_ECDH_anon_WITH_RC4_128_SHA",
+		0	},
+	{
+		49175,
+		"TLS_ECDH_anon_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		49176,
+		"TLS_ECDH_anon_WITH_AES_128_CBC_SHA",
+		0	},
+	{
+		49177,
+		"TLS_ECDH_anon_WITH_AES_256_CBC_SHA",
+		0	},
+	{
+		0,
+		"TLS_NULL_WITH_NULL_NULL",
+		0	},
+	{
+		1,
+		"TLS_RSA_WITH_NULL_MD5",
+		0	},
+	{
+		2,
+		"TLS_RSA_WITH_NULL_SHA",
+		0	},
+	{
+		4,
+		"TLS_RSA_WITH_RC4_128_MD5",
+		0	},
+	{
+		5,
+		"TLS_RSA_WITH_RC4_128_SHA",
+		0	},
+	{
+		10,
+		"TLS_RSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		59,
+		"TLS_RSA_WITH_NULL_SHA256",
+		0	},
+	{
+		60,
+		"TLS_RSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		61,
+		"TLS_RSA_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		13,
+		"TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		16,
+		"TLS_DH_RSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		19,
+		"TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		22,
+		"TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		62,
+		"TLS_DH_DSS_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		63,
+		"TLS_DH_RSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		64,
+		"TLS_DHE_DSS_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		103,
+		"TLS_DHE_RSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		104,
+		"TLS_DH_DSS_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		105,
+		"TLS_DH_RSA_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		106,
+		"TLS_DHE_DSS_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		107,
+		"TLS_DHE_RSA_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		24,
+		"TLS_DH_anon_WITH_RC4_128_MD5",
+		0	},
+	{
+		27,
+		"TLS_DH_anon_WITH_3DES_EDE_CBC_SHA",
+		0	},
+	{
+		108,
+		"TLS_DH_anon_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		109,
+		"TLS_DH_anon_WITH_AES_256_CBC_SHA256",
+		0	},
+	{
+		156,
+		"TLS_RSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		157,
+		"TLS_RSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		158,
+		"TLS_DHE_RSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		159,
+		"TLS_DHE_RSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		160,
+		"TLS_DH_RSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		161,
+		"TLS_DH_RSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		162,
+		"TLS_DHE_DSS_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		163,
+		"TLS_DHE_DSS_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		164,
+		"TLS_DH_DSS_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		165,
+		"TLS_DH_DSS_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		166,
+		"TLS_DH_anon_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		167,
+		"TLS_DH_anon_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		49187,
+		"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		49188,
+		"TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384",
+		0	},
+	{
+		49189,
+		"TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		49190,
+		"TLS_ECDH_ECDSA_WITH_AES_256_CBC_SHA384",
+		0	},
+	{
+		49191,
+		"TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		49192,
+		"TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384",
+		0	},
+	{
+		49193,
+		"TLS_ECDH_RSA_WITH_AES_128_CBC_SHA256",
+		0	},
+	{
+		49194,
+		"TLS_ECDH_RSA_WITH_AES_256_CBC_SHA384",
+		0	},
+	{
+		49195,
+		"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		49196,
+		"TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		49197,
+		"TLS_ECDH_ECDSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		49198,
+		"TLS_ECDH_ECDSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		49199,
+		"TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		49200,
+		"TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		49201,
+		"TLS_ECDH_RSA_WITH_AES_128_GCM_SHA256",
+		0	},
+	{
+		49202,
+		"TLS_ECDH_RSA_WITH_AES_256_GCM_SHA384",
+		0	},
+	{
+		255,
+		"TLS_EMPTY_RENEGOTIATION_INFO_SCSV",
+		0	},
+	{
+		65408,
+		"SSL_RSA_WITH_RC2_CBC_MD5",
+		0	},
+	{
+		65409,
+		"SSL_RSA_WITH_IDEA_CBC_MD5",
+		0	},
+	{
+		65410,
+		"SSL_RSA_WITH_DES_CBC_MD5",
+		0	},
+	{
+		65411,
+		"SSL_RSA_WITH_3DES_EDE_CBC_MD5",
+		0	},
+	{
+		65535,
+		"SSL_NO_SUCH_CIPHERSUITE",
+		0	},
+	/***** /Patch additions *****/
 {-1}
 };
 
diff -Naur a/ssl/ssldecode.c b/ssl/ssldecode.c
--- a/ssl/ssldecode.c	2002-08-17 05:33:17.000000000 +0400
+++ b/ssl/ssldecode.c	2017-10-18 12:40:18.000000000 +0400
@@ -51,6 +51,7 @@
 #include <openssl/ssl.h>
 #include <openssl/hmac.h>
 #include <openssl/evp.h>
+#include <openssl/md5.h>
 #include <openssl/x509v3.h>
 #endif
 #include "ssldecode.h"
@@ -131,7 +132,8 @@
     ssl_decode_ctx *d=0;
     int r,_status;
     
-    SSLeay_add_all_algorithms();
+    SSL_library_init();
+    OpenSSL_add_all_algorithms();
     if(!(d=(ssl_decode_ctx *)malloc(sizeof(ssl_decode_ctx))))
       ABORT(R_NO_MEMORY);
     if(!(d->ssl_ctx=SSL_CTX_new(SSLv23_server_method())))
