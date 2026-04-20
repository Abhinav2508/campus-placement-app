#!/bin/bash
echo "==> Running Migrations"
python manage.py migrate

echo "==> Collecting Static Files"
python manage.py collectstatic --noinput

echo "==> Ensuring Admin User exists"
python manage.py shell -c "from django.contrib.auth.models import User; User.objects.filter(username='admin').exists() or User.objects.create_superuser('admin', 'admin@example.com', 'admin123')"

echo "==> Starting Gunicorn"
gunicorn placement_backend.wsgi --bind 0.0.0.0:$PORT --log-file -
