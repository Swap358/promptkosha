-- PromptKosha demo content (all original text). Everything here can be edited or deleted in the admin panel.
-- Run once, AFTER both migrations. Images are left empty on purpose: upload your own in Admin > Media.

-- ------------------------------------------------------------ categories
insert into public.categories (name, slug, description, sort_order, meta_title, meta_description) values
 ('Portrait Prompts',          'portrait',        'Prompts for natural, studio and creative portraits with believable light and skin detail.', 1, 'AI Portrait Prompts to Copy', 'Copy ready-made AI portrait prompts for golden hour, studio and creative looks.'),
 ('Cinematic Prompts',         'cinematic',       'Movie-style scenes with dramatic lighting, lens choices and colour grading.',              2, 'Cinematic AI Prompts', 'Cinematic AI image and video prompts with lighting, lens and colour direction.'),
 ('Fashion Prompts',           'fashion',         'Editorial, street and traditional fashion looks for AI image tools.',                      3, 'AI Fashion Prompts', 'Fashion and style prompts for editorial and street looks.'),
 ('Cartoon & Anime Prompts',   'cartoon-anime',   'Illustrated avatars, anime portraits and playful 3D cartoon characters.',                  4, 'AI Cartoon and Anime Prompts', 'Copy cartoon, chibi and anime-style AI prompts.'),
 ('Festival Prompts',          'festival',        'Celebration portraits and greeting designs for festivals and special days.',               5, 'AI Festival Photo Prompts', 'Festival photo and poster prompts you can copy and customise.');

-- ----------------------------------------------------------- collections
insert into public.collections (name, slug, description, is_featured, meta_title, meta_description) values
 ('Trending AI Photo Prompts',  'trending-ai-photo-prompts', 'The prompts people are copying most right now.', true,  'Trending AI Photo Prompts', 'A hand-picked set of the most copied AI photo prompts.'),
 ('AI Photo Prompts for Girls', 'ai-photo-prompts-for-girls', 'Portrait and fashion prompts styled for girls.',    true,  'AI Photo Prompts for Girls', 'Portrait and fashion AI prompts for girls.'),
 ('Couple AI Photo Prompts',    'couple-ai-photo-prompts',   'Romantic and festive prompts for two people.',       true,  'Couple AI Photo Prompts', 'Prompts for couple portraits and celebrations.');

-- ----------------------------------------------------------------- tags
insert into public.tags (name, slug) values
 ('Portrait','portrait'),('Golden Hour','golden-hour'),('Cinematic','cinematic'),('Neon','neon'),
 ('Streetwear','streetwear'),('Saree','saree'),('Anime','anime'),('Festival','festival'),
 ('Couple','couple'),('Video','video'),('Template','template'),('Studio Lighting','studio-lighting');

-- --------------------------------------------------------------- prompts
-- Values: title, slug, short description, prompt, Hindi prompt, category, type, audience, tools, tips,
--         suitable for, featured, trending, pinned, template, days ago it was published.
insert into public.prompts
  (title, slug, short_description, prompt_text, prompt_text_hi, image_alt, category_id, prompt_type, audience,
   recommended_tools, how_to_use, tips, suitable_for, additional_content,
   is_featured, is_trending, is_pinned, is_template, status, published_at)
select v.title, v.slug, v.sd, v.pt, v.hi, v.title || ' (demo preview)',
  (select id from public.categories where slug = v.cat), v.ptype, v.aud, v.tools,
  case when v.ptype = 'video'
    then E'Copy the prompt.\nOpen your preferred AI video generator.\nPaste the prompt into the text box.\nChoose a 5 to 10 second length and 16:9 ratio.\nGenerate, then trim the best moment.'
    else E'Copy the prompt.\nOpen your preferred AI image generator.\nUpload a reference image if your tool supports it.\nPaste the copied prompt.\nGenerate and refine with small changes.' end,
  v.tips, v.suit,
  'Demo content. Replace this section with your own helpful, original guidance for ' || lower(v.title) || '.',
  v.feat, v.trend, v.pin, v.tpl, 'published', now() - (v.age || ' days')::interval
from (values
 ('Golden Hour Portrait Prompt','golden-hour-portrait-prompt','A warm sunset portrait with soft rim light and gentle bokeh.',
  'Portrait of a young woman standing in a wheat field at golden hour, warm sunlight behind her creating a soft rim light in her hair, shallow depth of field, creamy background blur, natural skin texture, calm expression, 85mm lens, soft film grain, warm amber tones.',
  'सुनहरी शाम के समय गेहूं के खेत में खड़ी एक युवती का पोर्ट्रेट, पीछे से आती गर्म धूप बालों पर नरम रोशनी बना रही है, कम गहराई वाला फोकस, धुंधला सुंदर बैकग्राउंड, प्राकृतिक त्वचा, शांत भाव, 85mm लेंस, हल्का फिल्म ग्रेन, गर्म सुनहरे रंग।',
  'portrait','image','girls', array['ChatGPT','Midjourney','Flux'],
  E'Add "backlit" if the face looks flat.\nKeep the lens at 85mm for natural proportions.\nTry "overcast" for a softer, cooler mood.',
  'Profile photos, social media posts and creators who want a warm, natural look.', true, true, false, false, 2),
 ('Moody Studio Portrait Prompt','moody-studio-portrait-prompt','A dark studio portrait with a single strong side light.',
  'Studio portrait of a young man in a black turtleneck, single softbox from the left, deep shadows on the right side of the face, dark grey backdrop, sharp eyes, subtle skin texture, 50mm lens, low-key lighting, muted colour palette.',
  null,'portrait','image','boys', array['Midjourney','Leonardo AI'],
  E'Say "low-key" to keep the shadows deep.\nAdd "catchlight in eyes" for a livelier look.',
  'Personal branding, profile pictures and dramatic photo edits.', false, false, false, false, 5),
 ('Rain-Soaked Street Cinematic Prompt','rain-soaked-street-cinematic-prompt','A wet city street at night, reflecting warm shop lights.',
  'Cinematic wide shot of a narrow city street at night after heavy rain, reflections of warm shop signs on the wet road, a lone figure with a transparent umbrella, light mist in the air, anamorphic lens flare, teal and orange colour grade, 35mm film look.',
  null,'cinematic','image','unisex', array['Midjourney','Flux','Google Gemini'],
  E'Use "anamorphic" for wide, stretched highlights.\nKeep one bright light source so the scene has a focal point.',
  'Story illustrations, thumbnails and mood boards.', false, true, false, false, 3),
 ('Neon Noir Movie Still Prompt','neon-noir-movie-still-prompt','A moody detective scene lit by pink and blue neon.',
  'Neon noir movie still, a detective in a long coat standing in a smoky alley, pink and blue neon signs casting colour on the walls, wet ground, deep shadows, shallow depth of field, grainy film texture, 2.39:1 aspect ratio.',
  null,'cinematic','image','unisex', array['Midjourney','Leonardo AI'],
  E'Name two neon colours only; more looks messy.\nAdd "2.39:1" for a widescreen crop.',
  'Concept art, posters and cinematic wallpapers.', false, false, false, false, 8),
 ('Minimal Streetwear Look Prompt','minimal-streetwear-look-prompt','A clean, neutral-toned street style photo.',
  'Full-body street style photo of a young man in an oversized beige hoodie, black cargo pants and white sneakers, walking past a concrete wall, soft overcast daylight, neutral colour palette, 35mm lens, candid pose, magazine-quality sharpness.',
  null,'fashion','image','boys', array['ChatGPT','Flux'],
  E'Describe each clothing item separately for better accuracy.\nUse "overcast" to avoid harsh shadows.',
  'Fashion creators, lookbooks and style inspiration boards.', false, false, false, false, 10),
 ('Elegant Saree Editorial Prompt','elegant-saree-editorial-prompt','A graceful saree look in warm window light.',
  'Editorial portrait of a woman in a deep green silk saree with a gold border, standing beside a tall arched window, soft natural light on the fabric, subtle jewellery, graceful pose, shallow depth of field, rich warm colours, medium format look.',
  null,'fashion','image','girls', array['ChatGPT','Midjourney'],
  E'Mention the fabric ("silk", "cotton") so the folds look right.\nKeep jewellery simple to avoid distortions.',
  'Traditional wear shoots, festive posts and boutique inspiration.', true, false, false, false, 4),
 ('Soft Watercolor Anime Portrait Prompt','soft-watercolor-anime-portrait-prompt','A gentle anime-style portrait with watercolor washes.',
  'Anime-style portrait of a teenager with wind-blown hair, soft watercolor washes in pastel blue and peach, delicate line art, subtle paper texture, gentle smile, light bloom around the edges, clean background.',
  null,'cartoon-anime','image','unisex', array['Leonardo AI','Midjourney','Flux'],
  E'Add "paper texture" for the hand-painted feel.\nUse two pastel colours to keep the palette calm.',
  'Avatars, wallpapers and illustrated profile pictures.', false, false, false, false, 6),
 ('Festive Couple Lantern Portrait Prompt','festive-couple-lantern-portrait-prompt','A warm festival evening portrait of a couple with lanterns.',
  'Portrait of a couple in traditional festive clothes, standing close and smiling, surrounded by glowing paper lanterns and small oil lamps, warm evening light, soft bokeh, rich gold and orange tones, natural poses, shallow depth of field, 50mm lens.',
  'पारंपरिक त्योहार के कपड़ों में एक जोड़े का पोर्ट्रेट, दोनों पास खड़े होकर मुस्कुरा रहे हैं, चारों ओर चमकती कागज़ की लालटेनें और छोटे दीये, शाम की गर्म रोशनी, नरम बोकेह, सुनहरे और नारंगी रंग, स्वाभाविक मुद्राएं, कम गहराई वाला फोकस, 50mm लेंस।',
  'festival','image','couple', array['ChatGPT','Midjourney','Google Gemini'],
  E'Say "standing close" to avoid stiff poses.\nName the clothing style you want, for example "kurta and lehenga".',
  'Couples, festival greetings and social media celebration posts.', true, true, true, false, 1),
 ('Cinematic Drone Flyover Video Prompt','cinematic-drone-flyover-video-prompt','A smooth aerial shot over a misty mountain valley.',
  'Cinematic drone shot slowly flying forward over a misty mountain valley at sunrise, rivers of fog between green hills, warm light breaking through clouds, smooth steady motion, natural colours, 16:9, 8 seconds.',
  null,'cinematic','video','unisex', array['Other AI Tools'],
  E'Keep camera motion to one simple move.\nShort clips (5 to 10 seconds) are usually more stable.',
  'Travel reels, intros and background footage.', false, true, false, false, 7),
 ('Character Portrait Builder Template','character-portrait-builder-template','A fill-in-the-blanks template for custom character portraits.',
  'Portrait of [age] [gender] with [hair style and colour], wearing [clothing], in [location], lit by [light type], [mood] expression, [lens] lens, [colour palette] colours, [art style].',
  null,'portrait','text','unisex', array['ChatGPT','Google Gemini','Midjourney'],
  E'Replace every [bracket] with your own words.\nKeep each blank to a few words for best results.',
  'Anyone who wants to build their own portrait prompts quickly.', false, false, false, true, 9)
) as v(title, slug, sd, pt, hi, cat, ptype, aud, tools, tips, suit, feat, trend, pin, tpl, age);

-- ------------------------------------------ link prompts to tags / collections
insert into public.prompt_tags (prompt_id, tag_id)
select p.id, t.id from (values
 ('golden-hour-portrait-prompt','portrait'),('golden-hour-portrait-prompt','golden-hour'),
 ('moody-studio-portrait-prompt','portrait'),('moody-studio-portrait-prompt','studio-lighting'),
 ('rain-soaked-street-cinematic-prompt','cinematic'),
 ('neon-noir-movie-still-prompt','cinematic'),('neon-noir-movie-still-prompt','neon'),
 ('minimal-streetwear-look-prompt','streetwear'),
 ('elegant-saree-editorial-prompt','saree'),
 ('soft-watercolor-anime-portrait-prompt','anime'),
 ('festive-couple-lantern-portrait-prompt','festival'),('festive-couple-lantern-portrait-prompt','couple'),
 ('cinematic-drone-flyover-video-prompt','video'),('cinematic-drone-flyover-video-prompt','cinematic'),
 ('character-portrait-builder-template','template'),('character-portrait-builder-template','portrait')
) as m(ps, ts)
join public.prompts p on p.slug = m.ps join public.tags t on t.slug = m.ts;

insert into public.prompt_collections (prompt_id, collection_id)
select p.id, c.id from (values
 ('golden-hour-portrait-prompt','trending-ai-photo-prompts'),
 ('rain-soaked-street-cinematic-prompt','trending-ai-photo-prompts'),
 ('festive-couple-lantern-portrait-prompt','trending-ai-photo-prompts'),
 ('cinematic-drone-flyover-video-prompt','trending-ai-photo-prompts'),
 ('golden-hour-portrait-prompt','ai-photo-prompts-for-girls'),
 ('elegant-saree-editorial-prompt','ai-photo-prompts-for-girls'),
 ('festive-couple-lantern-portrait-prompt','couple-ai-photo-prompts')
) as m(ps, cs)
join public.prompts p on p.slug = m.ps join public.collections c on c.slug = m.cs;

-- --------------------------------------------------------- static pages
insert into public.pages (title, slug, content, seo_title, seo_description, status) values
 ('About Us','about', E'## About us\nThis site collects original AI prompts for images, video and photo editing so you can find an idea, copy it and make something of your own.\n\n## What we publish\nEvery prompt is written or reviewed by our team and tagged by category, audience and the tools it suits.\n\nReplace this demo text with your own story.', 'About Us', 'Learn what this prompt gallery is and who is behind it.', 'published'),
 ('Contact Us','contact', E'Questions, suggestions or prompt ideas? Send us a message using the form below.', 'Contact Us', 'Get in touch with the team.', 'published'),
 ('Privacy Policy','privacy-policy', E'## Privacy policy\nThis is a starter template and not legal advice. Please replace it with a policy that fits your site and local law.\n\n## Information we collect\nIf you use the contact form or newsletter, we store the details you submit (name, email, message).\n\n## Cookies and advertising\nIf advertising or analytics are enabled, those providers may use cookies. Explain which ones here.\n\n## Contact\nUse the contact page for privacy questions.', 'Privacy Policy', 'How this website handles your information.', 'published'),
 ('Terms and Conditions','terms-and-conditions', E'## Terms and conditions\nThis is a starter template and not legal advice. Replace it with your own terms.\n\n## Use of prompts\nPrompts are provided for inspiration. Results depend on the AI tool you use.\n\n## Changes\nWe may update these terms from time to time.', 'Terms and Conditions', 'The terms for using this website.', 'published'),
 ('Disclaimer','disclaimer', E'## Disclaimer\nPrompts are shared for creative inspiration. We do not guarantee any particular result from any AI tool, and we are not affiliated with the AI tools mentioned.', 'Disclaimer', 'Important notes about the content on this website.', 'published'),
 ('DMCA / Copyright Policy','dmca-policy', E'## Copyright policy\nIf you believe content here infringes your copyright, contact us with the page address and details of your claim and we will review it promptly.\n\nThis is a starter template and not legal advice.', 'DMCA and Copyright Policy', 'How to report copyright concerns.', 'published');

-- --------------------------------------------------------------- settings
insert into public.site_settings (setting_key, setting_value) values
 ('site_name','PromptKosha'),('site_tagline','Discover the best AI prompts'),('site_logo',''),('favicon',''),
 ('site_url','http://localhost:3000'),
 ('site_description','Explore AI image, video and photo editing prompts. Copy your favourite prompt and create something extraordinary.'),
 ('contact_email',''),('footer_text','© PromptKosha. All rights reserved.'),
 ('social_instagram',''),('social_facebook',''),('social_pinterest',''),('social_youtube',''),('social_telegram',''),
 ('seo_default_title','PromptKosha: AI Prompt Gallery'),
 ('seo_default_description','Discover, preview and copy high-quality AI image, video and photo editing prompts.'),
 ('seo_og_image',''),('ga_id',''),('gsc_verification',''),('custom_header_code',''),
 ('prompts_per_page','20'),('newsletter_enabled','true'),('ads_enabled','false'),
 ('featured_collections_enabled','true'),('social_sharing_enabled','true'),
 ('home_seo_heading','Discover the Best AI Prompts for Your Creativity'),
 ('home_seo_description','Find inspiration, copy your favourite prompts and create something extraordinary.'),
 ('home_seo_content','Browse portrait, cinematic, fashion, cartoon and festival prompts. Every prompt shows the exact text to copy, the tools it suits and tips for better results.'),
 ('ad_header',''),('ad_home_after_hero',''),('ad_home_between',''),('ad_category',''),
 ('ad_prompt',''),('ad_sidebar',''),('ad_footer','');
