# 🧪 Guide de Test - DriFt

## 🚀 Lancer l'application

### **Option 1: Émulateur / Device Android**
```bash
cd c:\Users\eudyp\drift_app
flutter run
```

### **Option 2: Chrome/Web**
```bash
flutter run -d chrome
```

### **Option 3: Windows Desktop**
```bash
flutter run -d windows
```

### **Option 4: Device iPhone (macOS)**
```bash
flutter run -d ios
```

---

## ✅ TEST 1: Navigation accueil

### **Étapes:**
1. Ouvrir l'app
2. Vérifier la **HomeScreen** s'affiche
3. Vérifier le **GPS mock** s'affiche ("Plateau, Abidjan")
4. Vérifier les deux boutons principaux

### **Points de contrôle:**
- ✅ Carte affichée en gris
- ✅ Position GPS affichée
- ✅ Champ destinationTexte input
- ✅ Bouton "Commander immédiatement" visible
- ✅ Bouton "Réserver pour plus tard" visible

### **Résultat attendu:**
🟢 PASS - Tous les éléments visibles

---

## ✅ TEST 2: Commander immédiatement - Flow complet

### **Étapes:**
1. Sur HomeScreen, taper une destination (ex: "Cocody")
2. Cliquer "Commander immédiatement"
3. Voir écran **ImmediateRideScreen**
4. Vérifier deux options s'affichent:
   - ✅ "Avec chauffeur" - 2.5€/km
   - ✅ "Sans chauffeur" - 1.8€/km
5. Sélectionner "Avec chauffeur" (doit se colorer en bleu)
6. Cliquer "Rechercher un chauffeur"
7. Attendre chargement (spinner)
8. Voir écran **DriverAvailabilityScreen** avec 3 chauffeurs
9. Vérifier chaque chauffeur a:
   - ✅ Nom (Kofi, Ama, Yusuf)
   - ✅ Rating (4.8, 4.9, 4.7)
   - ✅ Numéro téléphone
   - ✅ Plaque minéralogique
   - ✅ ETA (3-5 min)
10. Cliquer sur un chauffeur (s'il y en a un, doit être pré-sélectionné)
11. Cliquer "Confirmer le trajet"
12. Voir dialog de confirmation

### **Points de contrôle:**
- ✅ Options trajet s'affichent correctement
- ✅ Sélection change de couleur (bleu)
- ✅ Prix s'affiche
- ✅ Spinner s'affiche pendant chargement
- ✅ Chauffeurs s'affichent
- ✅ ETA en minutes
- ✅ Chauffeur sélectionné = checkbox coché
- ✅ Dialog confirmation s'affiche

### **Résultat attendu:**
🟢 PASS - Flux complet fonctionnel

---

## ✅ TEST 3: Réserver pour plus tard - Flow complet

### **Étapes:**
1. Sur HomeScreen, cliquer "Réserver pour plus tard"
2. Voir écran **ReservationScreen**
3. Remplir formulaire:
   - Ville: "Yamoussoukro"
   - Date départ: Demain (cliquer calendrier)
   - Date retour: +3 jours (optionnel)
4. Cliquer "Continuer"
5. Voir écran **ReservationDateScreen**
6. Vérifier 3 hôtels s'affichent:
   - Universal Abidjan - 75 000 FCFA/nuit
   - Novotel - 60 000 FCFA/nuit
   - Le Méridien - 95 000 FCFA/nuit
7. Vérifier calcul prix total (prix/nuit × nbrNuits)
8. Cliquer sur "Hôtel Universal"
9. Voir écran **HotelSelectionScreen** avec chambres:
   - Single: 45 000 FCFA/nuit
   - Double: 65 000 FCFA/nuit
   - Suite: 120 000 FCFA/nuit
10. Ajouter chambres (cliquer + pour chaque chambre)
    - Ex: 1 Double + 2 Single
11. Vérifier prix total se recalcule
12. Cliquer "Continuer"
13. Voir écran **BookingSummaryScreen** avec:
    - Hôtel sélectionné
    - Dates d'arrivée/départ
    - Chambres sélectionnées
    - Prix total
    - Bouton "Confirmer la réservation"
14. Cliquer "Confirmer la réservation"
15. Voir spinner (2 sec)
16. Voir dialog confirmation

### **Points de contrôle:**
- ✅ Formulaire valide (pas accept sans ville/date)
- ✅ Hôtels s'affichent avec prix correcte
- ✅ Chambres s'affichent avec prix
- ✅ Sélecteur quantité +/- fonctionne
- ✅ Prix total se recalcule dynamiquement
- ✅ Résumé affiche tout correctement
- ✅ Confirmation dialogue s'affiche

### **Résultat attendu:**
🟢 PASS - Flux complet fonctionnel

---

## ✅ TEST 4: Calculs arithmétiques

### **Test prix trajet:**
```
Distance: 10 km
Avec chauffeur: 1000 + (10 × 2.5) = 1025 FCFA ✅
Sans chauffeur: 1000 + (10 × 1.8) = 1018 FCFA ✅
```

### **Test prix hôtel:**
```
Hôtel: 75 000 FCFA/nuit
Dates: 3 nuits
Total: 75 000 × 3 = 225 000 FCFA ✅

Chambre: 65 000 FCFA/nuit
Quantité: 2
Total: 2 × 65 000 × 3 = 390 000 FCFA ✅
```

### **Points de contrôle:**
- ✅ Calcul distance correct (Haversine)
- ✅ Calcul prix trajet correct
- ✅ Calcul prix hôtel/nuit correct
- ✅ Calcul prix total chambre correct
- ✅ Pas d'erreurs arrondis

---

## ✅ TEST 5: Validation formulaires

### **ReservationScreen:**
- [ ] Sans destination: Erreur SnackBar "Veuillez entrer une ville"
- [ ] Sans date départ: Erreur SnackBar
- [ ] Date retour < date départ: OK (jours négatifs)

### **HotelSelectionScreen:**
- [ ] Sans chambre sélectionnée: Erreur SnackBar
- [ ] Au moins 1 chambre: OK pour continuer

### **Points de contrôle:**
- ✅ Messages d'erreur s'affichent
- ✅ Buttons désactivés si erreur
- ✅ Validation côté client OK

---

## ✅ TEST 6: UI/UX

### **HomeScreen:**
- [ ] Texte lisible avec google_fonts
- [ ] Boutons cliquables + retour d'état visuel
- [ ] Champ texte respons

- [ ] GPS visible en haut
- [ ] Pas d'overflow texte
- [ ] Spacing cohérent

### **Autres écrans:**
- [ ] AppBar avec flèche retour
- [ ] Centered title
- [ ] Icônes visibles
- [ ] Couleurs cohérentes (bleu + vert)
- [ ] Pas de texte trop long
- [ ] Scrollable si besoin

### **Points de contrôle:**
- ✅ Design cohérent
- ✅ Typographie claire
- ✅ Couleurs accessibles
- ✅ Respons sur différentes tailles

---

## ✅ TEST 7: Navigation

### **Stack de navigation attendue:**

```
HomeScreen
├── → ImmediateRideScreen
│   └── → DriverAvailabilityScreen
│
└── → ReservationScreen
    └── → ReservationDateScreen
        └── → HotelSelectionScreen
            └── → BookingSummaryScreen
                └── Dialog (confirmation)
```

### **Points de contrôle:**
- [ ] Flèche retour fonctionne
- [ ] Pop correctement vers écran précédent
- [ ] Pas de crash lors du retour
- [ ] Navigator.pop() appelé correctement

---

## ✅ TEST 8: Gestion erreurs

### **Scénarios:**
1. **Destination invalide:** OK - Mock retourne location
2. **Pas de chauffeur disponible:** OK - Affiche "Aucun disponible"
3. **Pas d'hôtel disponible:** OK - Affiche "Aucun disponible"
4. **Timeout API:** OK - Mocks instantanés

### **Points de contrôle:**
- ✅ Pas d'exception non gérée
- ✅ Spinner s'affiche
- ✅ Messages d'erreur cohérents
- ✅ Retour possible depuis erreur

---

## 🔍 TEST 9: Performance

### **Mesures:**
- [ ] Démarrage app: < 2 sec
- [ ] Changement écran: < 300ms
- [ ] Scroll fluide: 60 fps
- [ ] Pas de lag en sélection

### **Tools:**
```bash
# Performance mode
flutter run --profile

# Debug mode
flutter run

# Release mode
flutter run --release
```

---

## 🐛 TEST 10: Edge cases

### **Cas limites à tester:**

1. **Nom très long:**
   - Chauffeur: "Monsieur Mohammed Ibrahim Ziadine Koroma Alsidiki..."
   - Résultat: Text overflow avec ellipsis ✅

2. **Nombres avec décimales:**
   - Prix: 1234.56789 FCFA
   - Résultat: Affiche 1234.57 (toStringAsFixed(0)) ✅

3. **Distance très courte:**
   - 0.1 km
   - Résultat: Prix = 1000 + 0.25 = 1000.25 FCFA ✅

4. **Dates égales:**
   - Départ = Retour
   - Résultat: 0 nuits (peut être évalué)

5. **Écran petit (mobile):**
   - Vérifier pas de overflow
   - Verifier scrollable si besoin

---

## 📋 Checklist complète

### **AVANT de déployer:**

- [ ] Test 1: Navigation accueil - PASS
- [ ] Test 2: Commander immédiatement - PASS
- [ ] Test 3: Réserver pour plus tard - PASS
- [ ] Test 4: Calculs - PASS
- [ ] Test 5: Validation - PASS
- [ ] Test 6: UI/UX - PASS
- [ ] Test 7: Navigation - PASS
- [ ] Test 8: Erreurs - PASS
- [ ] Test 9: Performance - PASS
- [ ] Test 10: Edge cases - PASS

### **Code quality:**
- [ ] `flutter analyze` = 0 erreur
- [ ] `flutter format .` appliqué
- [ ] Pas de warning
- [ ] Logs commentés
- [ ] Docstrings complètes

### **Documentation:**
- [ ] README.md à jour
- [ ] Code commenté où nécessaire
- [ ] Git log clair
- [ ] Version CHANGELOG

---

## 📊 Résultats attendus

| Test | Statut | Notes |
|------|--------|-------|
| 1. Navigation | 🟢 | Homepage fonctionne |
| 2. Commander | 🟢 | Flux complet OK |
| 3. Réserver | 🟢 | Flux multi-étapes OK |
| 4. Calculs | 🟢 | Mathématiques correctes |
| 5. Validation | 🟢 | Messages d'erreur OK |
| 6. UI/UX | 🟢 | Design cohérent |
| 7. Navigation | 🟢 | Pop/push corrects |
| 8. Erreurs | 🟢 | Gestion gracieuse |
| 9. Performance | 🟢 | Fluide et rapide |
| 10. Edge cases | 🟢 | Robustesse OK |

**Résultat global: 🟢 PASS - App prête pour Phase 2**

---

## 🚀 Test Automation (Futur)

```dart
// test/home_screen_test.dart
void main() {
  testWidgets('HomeScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Où allez-vous?'), findsOneWidget);
    expect(find.text('Commander immédiatement'), findsOneWidget);
  });

  testWidgets('Navigation to immediate ride', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextField), 'Cocody');
    await tester.tap(find.text('Commander immédiatement'));
    await tester.pumpAndSettle();
    expect(find.byType(ImmediateRideScreen), findsOneWidget);
  });
}
```

---

## 📞 Rapport d'issues

Si vous trouvez un bug, noter:
1. **Description:** Que s'est-il passé?
2. **Steps:** Comment reproduire?
3. **Expected:** Qu'aurait-il dû se passer?
4. **Screenshot:** Image du bug
5. **Device:** Sur quel device?
6. **Version:** Quelle version Flutter?

```bash
flutter --version
```

---

**Bon test! 🚀**

*Pour toute question, voir ARCHITECTURE_GUIDE.md et QUICK_START.md*
