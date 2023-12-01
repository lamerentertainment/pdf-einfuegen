from django.db import models

# Create your models here.

class PronomenErsetzungMaennlich(models.Model):
    wort = models.CharField(max_length=15)
    ersetzung = models.CharField(max_length=20)
    prioritaet = models.CharField(max_length=1)

class PronomenErsetzungWeiblich(models.Model):
    wort = models.CharField(max_length=15)
    ersetzung = models.CharField(max_length=20)
    prioritaet = models.CharField(max_length=1)

class OCRErsetzunge(models.Model):
    wort = models.CharField(max_length=30)
    ersetzung = models.CharField(max_length=30)

class VerbenErsetzungGegenwart(models.Model):
    wort = models.CharField(max_length=20)
    ersetzung = models.CharField(max_length=20)

class VerbenErsetzungSatzendeGegenwart(models.Model):
    wort = models.CharField(max_length=20)
    ersetzung = models.CharField(max_length=50)

class VerbenErsetzungVergangenheitsform(models.Model):
    wort = models.CharField(max_length=20)
    hilfsverb = models.CharField(max_length=10)
    ersetzung = models.CharField(max_length=30)
