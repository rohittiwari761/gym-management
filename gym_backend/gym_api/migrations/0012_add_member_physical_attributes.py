# Generated manually for member physical attributes

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('gym_api', '0011_notification'),
    ]

    operations = [
        migrations.AddField(
            model_name='member',
            name='height_cm',
            field=models.FloatField(blank=True, help_text='Height in centimeters', null=True),
        ),
        migrations.AddField(
            model_name='member',
            name='weight_kg',
            field=models.FloatField(blank=True, help_text='Weight in kilograms', null=True),
        ),
        migrations.AddField(
            model_name='member',
            name='profile_picture',
            field=models.ImageField(blank=True, null=True, upload_to='member_profiles/'),
        ),
        migrations.AddField(
            model_name='member',
            name='profile_picture_base64',
            field=models.TextField(blank=True, help_text='Base64 encoded profile picture for Railway deployment', null=True),
        ),
        migrations.AddField(
            model_name='member',
            name='profile_picture_content_type',
            field=models.CharField(blank=True, help_text='Content type of the base64 image', max_length=50, null=True),
        ),
    ]