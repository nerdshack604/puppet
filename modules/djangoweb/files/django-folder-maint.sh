#! /bin/bash
WorkingDirectory=$2
DjangoProject=$1


if [ -z "${DjangoProject}" ]; then echo "No djangoweb folder specified!... exiting" && exit; fi

if 	[ ! -f ${WorkingDirectory}/manage.py ]; then
	/usr/bin/virtualenv ${WorkingDirectory}; source ${WorkingDirectory}/bin/activate
	${WorkingDirectory}/bin/pip install -r ${WorkingDirectory}/requirements.txt
        ${WorkingDirectory}/bin/django-admin.py startproject ${DjangoProject} ${WorkingDirectory}
	if [ ! -f ${WorkingDirectory}/run ]; then mkdir --mode 0777 ${WorkingDirectory}/run; fi
fi

