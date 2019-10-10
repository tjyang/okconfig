VERSION		= 1.0
RELEASE		= 9
DATE		= $(shell date)
NEWRELEASE	= $(shell echo $$(($(RELEASE) + 1)))
PYTHON		= /usr/bin/python

TOPDIR = $(shell pwd)
DIRS	= build docs etc okconfig usr
PYDIRS	= okconfig bin
EXAMPLEDIR = 
MANPAGES = okconfig

all: rpms

versionfile:
	echo "version:" $(VERSION) > etc/version
	echo "release:" $(RELEASE) >> etc/version
	echo "source build date:" $(DATE) >> etc/version
	#echo "git commit:" $(shell git log -n 1 --pretty="format:%H") >> etc/version
	#echo "git date:" $(shell git log -n 1 --pretty="format:%cd") >> etc/version

#	echo $(shell git log -n 1 --pretty="format:git commit: %H from \(%cd\)") >> etc/version 
manpage:
	for manpage in $(MANPAGES); do (pod2man --center=$$manpage --release="" ./docs/$$manpage.pod | gzip -c > ./docs/$$manpage.1.gz); done


build: clean versionfile
	$(PYTHON) setup.py build -f

clean:
	-rm -f  MANIFEST
	-rm -rf dist/ build/
	-rm -rf *~
	-rm -rf rpm-build/
	-rm -rf docs/*.gz
	-rm -f etc/version
	#-for d in $(DIRS); do ($(MAKE) -C $$d clean ); done

clean_hard:
	-rm -rf $(shell $(PYTHON) -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")/okconfig 


clean_hardest: clean_rpms


install: build manpage
	$(PYTHON) setup.py install -f

install_hard: clean_hard install

install_harder: clean_harder install

install_hardest: clean_harder clean_rpms rpms install_rpm 

install_rpm:
	-rpm -Uvh rpm-build/okconfig-$(VERSION)-$(NEWRELEASE)$(shell rpm -E "%{?dist}").noarch.rpm


recombuild: install_harder 

clean_rpms:
	-rpm -e okconfig

sdist: 
	$(PYTHON) setup.py sdist

pychecker:
	-for d in $(PYDIRS); do ($(MAKE) -C $$d pychecker ); done   
pyflakes:
	-for d in $(PYDIRS); do ($(MAKE) -C $$d pyflakes ); done	

money: clean
	-sloccount --addlang "makefile" $(TOPDIR) $(PYDIRS) $(EXAMPLEDIR) 

testit: clean
	-cd test; sh test-it.sh

unittest:
	-nosetests -v -w test/unittest

rpms: build manpage sdist
	mkdir -p rpm-build
	cp dist/*.gz rpm-build/
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir  %{_topdir}" \
	-ba okconfig.spec


ps:
	rm -f /tmp/*.ps /tmp/*.pdf
	(cd  usr/bin/;a2ps2s1c.sh ./okconfig)
	(cd  okconfig;a2ps2s1c.sh ./__init__.py)
	(cd  okconfig;a2ps2s1c.sh ./config.py)  
	(cd  okconfig;a2ps2s1c.sh ./helper_functions.py)
	(cd  okconfig;a2ps2s1c.sh ./migration_tool.py)  
	(cd  okconfig;a2ps2s1c.sh ./network_scan.py)

pdf:
	( cd /tmp; ps2pdf ./config.py.ps		   )
	( cd /tmp; ps2pdf ./helper_functions.py.ps	   )
	( cd /tmp; ps2pdf ./__init__.py.ps		   )
	( cd /tmp; ps2pdf ./migration_tool.py.ps	   )
	( cd /tmp; ps2pdf ./network_scan.py.ps	   )
	( cd /tmp; ps2pdf ./okconfig.ps             )  
	( ls -lrt /tmp/*.pdf)
