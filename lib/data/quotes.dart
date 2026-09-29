import 'dart:math';

import '../models/quote.dart';

/// 60 curated quotes: 20 each from the Bible, Bhagavad Gita and Quran.
const List<Quote> allQuotes = [
  // ─────────────── BIBLE (20) ───────────────
  Quote(id: 1, text: 'I can do all things through Christ who strengthens me.', source: ScriptureSource.bible, citation: 'Philippians 4:13'),
  Quote(id: 2, text: 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.', source: ScriptureSource.bible, citation: 'Jeremiah 29:11'),
  Quote(id: 3, text: 'The Lord is my shepherd; I shall not want.', source: ScriptureSource.bible, citation: 'Psalm 23:1'),
  Quote(id: 4, text: 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.', source: ScriptureSource.bible, citation: 'Joshua 1:9'),
  Quote(id: 5, text: 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.', source: ScriptureSource.bible, citation: 'Proverbs 3:5–6'),
  Quote(id: 6, text: 'The Lord is my light and my salvation — whom shall I fear? The Lord is the stronghold of my life — of whom shall I be afraid?', source: ScriptureSource.bible, citation: 'Psalm 27:1'),
  Quote(id: 7, text: 'Come to me, all you who are weary and burdened, and I will give you rest.', source: ScriptureSource.bible, citation: 'Matthew 11:28'),
  Quote(id: 8, text: 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.', source: ScriptureSource.bible, citation: 'Romans 12:2'),
  Quote(id: 9, text: 'And we know that in all things God works for the good of those who love him.', source: ScriptureSource.bible, citation: 'Romans 8:28'),
  Quote(id: 10, text: 'Even though I walk through the darkest valley, I will fear no evil, for you are with me.', source: ScriptureSource.bible, citation: 'Psalm 23:4'),
  Quote(id: 11, text: 'Cast all your anxiety on him because he cares for you.', source: ScriptureSource.bible, citation: '1 Peter 5:7'),
  Quote(id: 12, text: 'The Lord is close to the brokenhearted and saves those who are crushed in spirit.', source: ScriptureSource.bible, citation: 'Psalm 34:18'),
  Quote(id: 13, text: 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged.', source: ScriptureSource.bible, citation: 'Joshua 1:9'),
  Quote(id: 14, text: 'Wait for the Lord; be strong and take heart and wait for the Lord.', source: ScriptureSource.bible, citation: 'Psalm 27:14'),
  Quote(id: 15, text: 'God is our refuge and strength, an ever-present help in trouble.', source: ScriptureSource.bible, citation: 'Psalm 46:1'),
  Quote(id: 16, text: 'Let us not become weary in doing good, for at the proper time we will reap a harvest if we do not give up.', source: ScriptureSource.bible, citation: 'Galatians 6:9'),
  Quote(id: 17, text: 'For nothing will be impossible with God.', source: ScriptureSource.bible, citation: 'Luke 1:37'),
  Quote(id: 18, text: 'Delight yourself in the Lord, and he will give you the desires of your heart.', source: ScriptureSource.bible, citation: 'Psalm 37:4'),
  Quote(id: 19, text: 'You are the light of the world. A town built on a hill cannot be hidden.', source: ScriptureSource.bible, citation: 'Matthew 5:14'),
  Quote(id: 20, text: 'I have told you these things so that in me you may have peace. In this world you will have trouble. But take heart! I have overcome the world.', source: ScriptureSource.bible, citation: 'John 16:33'),

  // ─────────────── BHAGAVAD GITA (20) ───────────────
  Quote(id: 21, text: 'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 47'),
  Quote(id: 22, text: 'The soul is never born nor dies at any time. It has not come into being, does not come into being, and will not come into being. It is unborn, eternal, ever-existing, and primeval.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 20'),
  Quote(id: 23, text: 'Set thy heart upon thy work, but never on its reward.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 47'),
  Quote(id: 24, text: 'Man is made by his belief. As he believes, so he is.', source: ScriptureSource.gita, citation: 'Chapter 17, Verse 3'),
  Quote(id: 25, text: 'The mind acts like an enemy for those who do not control it.', source: ScriptureSource.gita, citation: 'Chapter 6, Verse 6'),
  Quote(id: 26, text: 'A person can rise through the efforts of his own mind; or draw himself down, in the same manner. Because each person is his own friend or enemy.', source: ScriptureSource.gita, citation: 'Chapter 6, Verse 5'),
  Quote(id: 27, text: 'For him who has conquered the mind, the mind is the best of friends; but for one who has failed to do so, his very mind will be the greatest enemy.', source: ScriptureSource.gita, citation: 'Chapter 6, Verse 6'),
  Quote(id: 28, text: 'Change is the law of the universe. You can be a millionaire or a pauper in an instant.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 14'),
  Quote(id: 29, text: 'Never the spirit was born; the spirit shall cease to be never. Never was time it was not; End and Beginning are dreams.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 19'),
  Quote(id: 30, text: 'When meditation is mastered, the mind is unwavering like the flame of a lamp in a windless place.', source: ScriptureSource.gita, citation: 'Chapter 6, Verse 19'),
  Quote(id: 31, text: 'Perform your obligatory duty, because action is indeed better than inaction.', source: ScriptureSource.gita, citation: 'Chapter 3, Verse 8'),
  Quote(id: 32, text: 'Whatever happened, happened for the good. Whatever is happening, is happening for the good. Whatever will happen, will also happen for the good.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 14'),
  Quote(id: 33, text: 'You came empty-handed, and you will leave empty-handed. What is yours today belonged to someone else yesterday and will belong to someone else tomorrow.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 14'),
  Quote(id: 34, text: 'The one who sees inaction in action, and action in inaction, is wise among men.', source: ScriptureSource.gita, citation: 'Chapter 4, Verse 18'),
  Quote(id: 35, text: 'Reshape yourself through the power of your will; never let yourself be degraded by self-will.', source: ScriptureSource.gita, citation: 'Chapter 6, Verse 5'),
  Quote(id: 36, text: 'Lust, anger, and greed are the three gates to self-destructive hell. Therefore, one should abandon all three.', source: ScriptureSource.gita, citation: 'Chapter 16, Verse 21'),
  Quote(id: 37, text: 'Among thousands of persons, hardly one strives for perfection, and among those who have achieved perfection, hardly one knows Me in truth.', source: ScriptureSource.gita, citation: 'Chapter 7, Verse 3'),
  Quote(id: 38, text: 'One who is not disturbed in mind even amidst the threefold miseries or elated when there is happiness, and who is free from attachment, fear, and anger, is called a sage of steady mind.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 56'),
  Quote(id: 39, text: 'Live without attachment to the fruits of your actions. Offer all your work as a sacrifice to God.', source: ScriptureSource.gita, citation: 'Chapter 9, Verse 27'),
  Quote(id: 40, text: 'The soul which is not moved, the soul that with a strong and constant calm takes sorrow and takes joy indifferently, lives in the life undying.', source: ScriptureSource.gita, citation: 'Chapter 2, Verse 15'),

  // ─────────────── QURAN (20) ───────────────
  Quote(id: 41, text: 'Indeed, with hardship comes ease.', source: ScriptureSource.quran, citation: 'Surah Ash-Sharh 94:6'),
  Quote(id: 42, text: 'And He found you lost and guided you.', source: ScriptureSource.quran, citation: 'Surah Ad-Duha 93:7'),
  Quote(id: 43, text: 'Verily, Allah will not change the condition of a people until they change what is in themselves.', source: ScriptureSource.quran, citation: "Surah Ar-Ra'd 13:11"),
  Quote(id: 44, text: 'Do not lose hope, nor be sad. You will surely be victorious if you are true believers.', source: ScriptureSource.quran, citation: 'Surah Al Imran 3:139'),
  Quote(id: 45, text: 'And whoever puts their trust in Allah, He will be enough for them.', source: ScriptureSource.quran, citation: 'Surah At-Talaq 65:3'),
  Quote(id: 46, text: 'On no soul does Allah place a burden greater than it can bear.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:286'),
  Quote(id: 47, text: 'And seek help through patience and prayer; indeed, it is difficult except for the humbly submissive to Allah.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:45'),
  Quote(id: 48, text: 'So remember Me; I will remember you. And be grateful to Me and do not deny Me.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:152'),
  Quote(id: 49, text: 'And your Lord says: Call upon Me; I will respond to you.', source: ScriptureSource.quran, citation: 'Surah Ghafir 40:60'),
  Quote(id: 50, text: 'Allah does not burden a soul beyond that it can bear.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:286'),
  Quote(id: 51, text: 'Indeed, Allah is with those who are patient.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:153'),
  Quote(id: 52, text: 'And He is with you wherever you are. And Allah, of what you do, is Seeing.', source: ScriptureSource.quran, citation: 'Surah Al-Hadid 57:4'),
  Quote(id: 53, text: 'Speak good words to people.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:83'),
  Quote(id: 54, text: 'So be patient. Indeed, the promise of Allah is truth.', source: ScriptureSource.quran, citation: 'Surah Ar-Rum 30:60'),
  Quote(id: 55, text: 'Who, when disaster strikes them, say: Indeed we belong to Allah, and indeed to Him we will return.', source: ScriptureSource.quran, citation: 'Surah Al-Baqarah 2:156'),
  Quote(id: 56, text: 'The bravest heart is the one that stays near Allah even when it is in pain.', source: ScriptureSource.quran, citation: 'Surah Az-Zumar 39:10'),
  Quote(id: 57, text: "And We have certainly made the Qur'an easy for remembrance, so is there any who will remember?", source: ScriptureSource.quran, citation: 'Surah Al-Qamar 54:17'),
  Quote(id: 58, text: 'It is He who sent down tranquillity into the hearts of the believers.', source: ScriptureSource.quran, citation: 'Surah Al-Fath 48:4'),
  Quote(id: 59, text: 'For indeed, with hardship will be ease. Indeed, with hardship will be ease.', source: ScriptureSource.quran, citation: 'Surah Ash-Sharh 94:5–6'),
  Quote(id: 60, text: 'And my success is not but through Allah. Upon Him I have relied, and to Him I return.', source: ScriptureSource.quran, citation: 'Surah Hud 11:88'),
];

final Random _random = Random();

List<Quote> quotesBySource(ScriptureSource? source) => source == null
    ? allQuotes
    : allQuotes.where((q) => q.source == source).toList();

/// Returns a random quote, optionally limited to one scripture.
/// When [excluding] is given, avoids repeating that quote back-to-back.
Quote randomQuote({ScriptureSource? source, Quote? excluding}) {
  final pool = quotesBySource(source);
  if (pool.length > 1 && excluding != null) {
    final filtered = pool.where((q) => q.id != excluding.id).toList();
    return filtered[_random.nextInt(filtered.length)];
  }
  return pool[_random.nextInt(pool.length)];
}
