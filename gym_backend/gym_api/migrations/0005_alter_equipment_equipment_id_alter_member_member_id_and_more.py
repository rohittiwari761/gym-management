# Generated by Django 5.2.3 on 2025-07-02 12:06

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("gym_api", "0004_alter_membershippayment_payment_id_and_more"),
    ]

    operations = [
        migrations.AlterField(
            model_name="equipment",
            name="equipment_id",
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AlterField(
            model_name="member",
            name="member_id",
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AlterField(
            model_name="trainer",
            name="trainer_id",
            field=models.CharField(blank=True, max_length=20),
        ),
    ]
