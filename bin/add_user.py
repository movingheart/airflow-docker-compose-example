#!/usr/bin/env python

"""
FileName: add_user
Author: deepinwst
Email: wanshitao@donews.com
Date: 2020/8/7 10:39:12
"""

from airflow import models, settings
from airflow.contrib.auth.backends.password_auth import PasswordUser
user = PasswordUser(models.User())
user.username = 'admin'
user.email = 'admin@example.com'
user.password = '123456'
session = settings.Session()
session.add(user)
session.commit()
session.close()
