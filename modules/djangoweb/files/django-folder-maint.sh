#! /bin/bash
WorkingDirectory=$2
DjangoProject=$1


if [ -z "${DjangoProject}" ]; then echo "No djangoweb folder specified!... exiting" && exit; fi

if 	[ ! -f ${WorkingDirectory}/manage.py ]; then
	/usr/bin/virtualenv ${WorkingDirectory}; source ${WorkingDirectory}/bin/activate
        echo -e "Django\ngunicorn\nuWSGI" > ${WorkingDirectory}/requirements.txt
	${WorkingDirectory}/bin/pip install -r ${WorkingDirectory}/requirements.txt
        ${WorkingDirectory}/bin/django-admin.py startproject ${DjangoProject} ${WorkingDirectory}
	mkdir --mode 0777 ${WorkingDirectory}/run
fi
wait

