# Generated by Django 5.2.3 on 2025-07-03 07:29

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("gym_api", "0007_gymowner_profile_picture"),
    ]

    operations = [
        migrations.AlterField(
            model_name="membershippayment",
            name="payment_id",
            field=models.CharField(blank=True, max_length=20),
        ),
    ]
