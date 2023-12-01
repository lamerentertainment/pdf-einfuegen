import json

from django.http import JsonResponse, HttpResponse
from .converters import als_aussage_formatieren, von_pdf_einfuegen
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render


@csrf_exempt
def transform_text(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body.decode('utf-8'))
            input_text = data.get('text', '')
            geschlecht = data.get('geschlecht', 'm')
            transformed_text = als_aussage_formatieren(textstelle=input_text,
                                                       geschlecht=geschlecht)
            response_data = {'transformed_text': transformed_text}
            return JsonResponse(response_data)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)


def index(request):
    return render(request, "courtapi/index.html")

def showcase(request):
    return render(request, "courtapi/showcase.html")

def conversion_result(request):
    eingabetext = request.POST.get('pasteTextarea', 'Fehler')
    if 'pasteButtonPDFText' in request.POST:
        ausgabetext = von_pdf_einfuegen(textstelle=eingabetext, hervorhebung=True)
    if 'pasteButtonAussageMann' in request.POST:
        ausgabetext = als_aussage_formatieren(textstelle=eingabetext, geschlecht='m', hervorhebung=True)
    if 'pasteButtonAussageFrau' in request.POST:
        ausgabetext = als_aussage_formatieren(textstelle=eingabetext, geschlecht='w', hervorhebung=True)
    eingabetext = eingabetext.replace("\n", "<br>")
    eingabetext = eingabetext.replace("- ", "- <br>")
    eingabetext = eingabetext.replace("  ", " <br>")
    return HttpResponse(f'<p>{ausgabetext}</p>'
                        f'<br>'
                        f'<h2>Einfügung ohne Formatierung</h2>'
                        f'<p>{eingabetext}</p>')


