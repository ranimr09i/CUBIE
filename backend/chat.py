
# import os
# import re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio
# from fastapi.staticfiles import StaticFiles

# chat_router = APIRouter()
# client = OpenAI(
#     api_key="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"
# )

# # تتبع الأدوار
# story_turns = {}

# def get_story_length_for_grade(grade_level: str):
#     if grade_level == 'KG':
#         return "قصيرة جداً (حوالي 40 إلى 60 كلمة)"
#     elif grade_level in ['G1', 'G2']:
#         return "قصيرة (حوالي 80 إلى 100 كلمة)"
#     else:
#         return "متوسطة (حوالي 120 كلمة)"

# # دالة محسنة لاستخراج التاق حتى لو كان وسط مسافات
# def extract_story_and_mode(full_response: str):
#     # نبحث عن التاق في أي مكان في آخر النص
#     # البحث عن واحد من التاقات المتوقعة
#     modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
#     found_mode = "TILTZ" # الافتراضي في حال عدم العثور على تاق لليمين/اليسار
    
#     # تنظيف النص
#     clean_response = full_response.strip()
    
#     # البحث عن آخر تاق موجود في النص
#     matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
#     if matches:
#         found_mode = matches[-1] # نأخذ آخر تاق وجدناه
#         # نحذف التاق من النص لعرض القصة فقط
#         story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
#         return story_part, found_mode
    
#     return clean_response, found_mode

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

# # دالة لترجمة رد المكعب إلى جملة عربية يفهمها الراوي
# def translate_answer_to_context(answer: str):
#     answer = answer.upper().strip()
#     if "LEFT" in answer:
#         return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
#     elif "RIGHT" in answer:
#         return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
#     elif "FRONT" in answer:
#         return "الطفل قام بإمالة المكعب للأمام."
#     elif "BACK" in answer:
#         return "الطفل قام بإمالة المكعب للخلف."
#     elif "SHAKE" in answer:
#         return "الطفل قام بهز المكعب بقوة."
#     else:
#         return f"الطفل قام باختيار: {answer}"

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row
#     story_length_prompt = get_story_length_for_grade(grade)
#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
#     prefs = f"نوع القصة: {genre}؛ وصف إضافي: {description}."
    
#     system_prompt = (
#         "أنت 'كيوبي'، راوي قصص تفاعلية ذكي للأطفال. تتحدث بالعربية الفصحى البسيطة والممتعة."
#         f"بيانات الطفل: {child_info} {prefs}"
#     )
    
#     # تحسين التعليمات لضمان التطابق بين السؤال والتاق
#     user_task_prompt = (
#         f"ابدأ القصة بمقدمة مشوقة. الطول المطلوب: {story_length_prompt}.\n"
#         "القاعدة الذهبية: يجب أن تنهي هذا الجزء بسؤال يطلب من الطفل القيام بحركة محددة للمتابعة.\n"
#         "اختر نوعاً واحداً فقط من الأسئلة التالية وأضف الكود الخاص به في نهاية النص تماماً:\n\n"
#         "1. إذا كان السؤال عن اختيار اتجاه (يمين أو يسار): اكتب القصة ثم [TILTZ]\n"
#         "2. إذا كان السؤال عن اختيار (أمام أو خلف): اكتب القصة ثم [TILTY]\n"
#         "3. إذا كان السؤال يتطلب حركة عشوائية أو مشوقة (مثل: هز الشجرة، اركض): اكتب القصة ثم [SHAKE]\n\n"
#         "مثال: '...هل يذهب لليمين نحو الغابة أم لليسار نحو النهر؟' [TILTZ]"
#     )

#     print("🔄 [OpenAI] Start Story...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": user_task_prompt}
#         ]
#     )
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None))
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     print(f"🎧 [Audio] Generating part 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, 
#         "audio_url": audio_url,
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade)

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     # ترجمة استجابة الطفل للسياق العربي
#     child_action_desc = translate_answer_to_context(answer)

#     base_system_prompt = (
#         "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال."
#         f"الطفل: {name}, {age} سنوات."
#     )
    
#     # تزويد الذكاء الاصطناعي بالسياق الكامل: القصة السابقة + ماذا فعل الطفل بالضبط
#     message_history = [
#         {"role": "system", "content": base_system_prompt},
#         {"role": "assistant", "content": old_story}, # القصة القديمة
#         {"role": "user", "content": f"حدث الآن: {child_action_desc}"} # التوضيح بالعربي
#     ]

#     if turns >= max_turns:
#         instruction = (
#             f"اكتب خاتمة للقصة ({story_length_prompt}) بناءً على اختيار الطفل الأخير.\n"
#             "اجعل النهاية سعيدة ومناسبة.\n"
#             "يجب أن ينتهي النص بـ [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"اكمل القصة بحدث جديد ({story_length_prompt}) يترتب على اختيار الطفل.\n"
#             "ثم انهِ الفقرة بسؤال تفاعلي جديد.\n"
#             "القواعد:\n"
#             "- لسؤال يمين/يسار: انهِ النص بـ [TILTZ]\n"
#             "- لسؤال أمام/خلف: انهِ النص بـ [TILTY]\n"
#             "- لسؤال هز/حركة: انهِ النص بـ [SHAKE]\n"
#             "التزم بوضع الكود الصحيح الذي يطابق سؤالك."
#         )
#         finished = False
        
#     message_history.append({"role": "system", "content": instruction})

#     print(f"🔄 [OpenAI] Continue Turn {turns}...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=message_history
#     )
    
#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] Generating Turn {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part,
#         "audio_url": audio_url,
#         "story_end": finished,
#         "required_move": question_mode
#     }






# import os
# import re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio

# chat_router = APIRouter()

# # تأكد من أن المفتاح موجود في متغيرات البيئة أو ضعه هنا
# client = OpenAI(api_key="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")

# # تتبع أدوار القصة
# story_turns = {}

# def get_story_length_for_grade(grade_level: str):
#     """
#     تحديد طول القصة بناءً على المرحلة الدراسية وفقاً لجدول المعايير.
#     """
#     # تنظيف المدخلات لضمان المطابقة
#     grade = grade_level.upper().strip()
    
#     if grade == 'KG':
#         return "قصيرة جداً (من 70 إلى 100 كلمة)"
#     elif grade == 'G1':
#         return "قصيرة (من 120 إلى 180 كلمة)"
#     elif grade == 'G2':
#         return "متوسطة القصر (من 200 إلى 300 كلمة)"
#     elif grade == 'G3':
#         return "متوسطة (من 300 إلى 450 كلمة)"
#     elif grade == 'G4':
#         return "متوسطة الطول (من 450 إلى 600 كلمة)"
#     elif grade == 'G5':
#         return "طويلة (من 600 إلى 800 كلمة)"
#     elif grade == 'G6':
#         return "طويلة جداً (من 800 إلى 1000 كلمة)"
#     else:
#         # افتراضي في حال لم يطابق شيء
#         return "متوسطة (حوالي 150 كلمة)"

# def extract_story_and_mode(full_response: str):
#     modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
#     found_mode = "TILTZ" # الافتراضي
    
#     clean_response = full_response.strip()
    
#     # البحث عن التاق في النص
#     matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
#     if matches:
#         found_mode = matches[-1]
#         # حذف التاق من النص للعرض
#         story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
#         return story_part, found_mode
    
#     return clean_response, found_mode

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

# def translate_answer_to_context(answer: str):
#     answer = answer.upper().strip()
#     if "LEFT" in answer:
#         return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
#     elif "RIGHT" in answer:
#         return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
#     elif "FRONT" in answer:
#         return "الطفل قام بإمالة المكعب للأمام."
#     elif "BACK" in answer:
#         return "الطفل قام بإمالة المكعب للخلف."
#     elif "SHAKE" in answer:
#         return "الطفل قام بهز المكعب بقوة."
#     else:
#         return f"الطفل قام باختيار: {answer}"

# # أمثلة (Few-Shot) لتدريب النموذج على التنسيق المطلوب بدقة
# FEW_SHOT_EXAMPLES = [
#     {
#         "role": "user", 
#         "content": "ابدأ القصة. الطفل: أحمد، 5 سنوات. الموضوع: الفضاء."
#     },
#     {
#         "role": "assistant",
#         "content": "كان يا ما كان، في محطة فضاء بعيدة، يعيش رائد فضاء شجاع اسمه أحمد. كان أحمد يحب النظر للنجوم اللامعة. وفجأة، رأى كوكباً غريباً يلمع بألوان قوس قزح! أسرع أحمد لمركبته الفضائية، لكنه وجد الباب مغلقاً ويحتاج لقوة لفتحه. هل يمكنك مساعدة أحمد في فتح الباب؟ هيا، قم بهز المكعب بقوة ليفتح الباب! [SHAKE]"
#     },
#     {
#         "role": "user",
#         "content": "اكمل القصة. الطفل قام بـ: هز المكعب."
#     },
#     {
#         "role": "assistant",
#         "content": "رائع! فتح الباب بقوة وانطلق أحمد بمركبته نحو الكوكب الملون. عندما اقترب، وجد طريقين: طريق مليء بالنجوم المتلألئة لليمين، وطريق فيه نيازك سريعة لليسار. ساعد أحمد في القيادة. هل نذهب لليمين نحو النجوم أم لليسار نحو النيازك؟ قم بإمالة المكعب لليمين أو اليسار لاختيار الطريق. [TILTZ]"
#     }
# ]

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row
#     story_length_prompt = get_story_length_for_grade(grade)
#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
    
#     system_prompt = (
#         "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال. أسلوبك مشوق وبسيط."
#         "قوانين صارمة جداً للإجابة:\n"
#         "1. اسرد جزءاً من القصة باللغة العربية الفصحى السهلة.\n"
#         "2. في نهاية كل رد، يجب أن تطلب من الطفل القيام بحركة فيزيائية بالمكعب.\n"
#         "3. اذكر اسم الحركة بوضوح للطفل (مثلاً: 'هز المكعب'، 'أمل المكعب لليمين').\n"
#         "4. اختم الرد فوراً بـ [TAG] الخاص بالحركة المختارة.\n"
#         "التاقات المسموحة فقط: [TILTZ] لليمين/اليسار، [TILTY] للأمام/الخلف، [SHAKE] للهز."
#     )
    
#     user_task_prompt = (
#         f"معلومات الطفل: {child_info}\n"
#         f"نوع القصة: {genre}. تفاصيل: {description}.\n"
#         f"اكتب بداية القصة ({story_length_prompt}).\n"
#         "انهِ الفقرة بسؤال يطلب حركة. مثال: 'هل نذهب للغابة (يمين) أم للنهر (يسار)؟ أمل المكعب لليمين أو اليسار!' [TILTZ]"
#     )

#     # بناء الرسائل مع الأمثلة
#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES) # إضافة الأمثلة لزيادة الالتزام
#     messages.append({"role": "user", "content": user_task_prompt})

#     print("🔄 [OpenAI] Start Story...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.7  # تقليل العشوائية قليلاً لزيادة الالتزام بالتعليمات
#     )
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     # حفظ القصة
#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None))
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     print(f"🎧 [Audio] Generating part 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, 
#         "audio_url": audio_url,
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade)

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     child_action_desc = translate_answer_to_context(answer)

#     # إعادة بناء الـ System Prompt لضمان بقاء التعليمات حاضرة
#     system_prompt = (
#         "أنت 'كيوبي'، راوي قصص. "
#         "مهم جداً: يجب أن ينتهي كل رد بطلب حركة فيزيائية واضحة من الطفل (هز، إمالة) ثم التاق المناسب ([SHAKE], [TILTZ], [TILTY])."
#     )

#     # تجميع سياق الرسائل
#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES) # تذكير النموذج بالأمثلة مرة أخرى
    
#     # إضافة ملخص بسيط للسياق بدلاً من القصة كاملة لتوفير التوكنز (اختياري، لكن هنا نرسل القصة كـ assistant history)
#     # ملاحظة: في التطبيقات الحقيقية الطويلة يفضل تلخيص القصة، هنا سنعتمد على آخر جزء
#     messages.append({"role": "assistant", "content": old_story}) 
    
#     if turns >= max_turns:
#         instruction = (
#             f"الطفل قام بـ: {child_action_desc}\n"
#             f"هذه هي النهاية. اكتب خاتمة سعيدة ومناسبة لطول ({story_length_prompt}).\n"
#             "يجب أن ينتهي النص بـ [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"الحدث السابق: {child_action_desc}\n"
#             f"اكمل القصة بحدث جديد ({story_length_prompt}).\n"
#             "1. تفاعل مع حركة الطفل.\n"
#             "2. اختم بسؤال يتطلب حركة جديدة (حدد الحركة بوضوح في النص، مثلاً: 'هز المكعب لتطير الطائرة!').\n"
#             "3. ضع التاق المناسب في النهاية ([SHAKE] أو [TILTZ] أو [TILTY])."
#         )
#         finished = False
        
#     messages.append({"role": "user", "content": instruction})

#     print(f"🔄 [OpenAI] Continue Turn {turns}...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.7
#     )
    
#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] Generating Turn {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part,
#         "audio_url": audio_url,
#         "story_end": finished,
#         "required_move": question_mode
#     }









#//////

# import os
# import re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio

# chat_router = APIRouter()

# # تأكد من أن المفتاح موجود في متغيرات البيئة أو ضعه هنا
# client = OpenAI(api_key="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")

# # تتبع أدوار القصة
# story_turns = {}

# def get_story_length_for_grade(grade_level: str):
#     """
#     تحديد طول القصة بناءً على المرحلة الدراسية وفقاً لجدول المعايير.
#     """
#     grade = grade_level.upper().strip()
#     if grade == 'KG':
#         return "قصيرة جداً (من 70 إلى 100 كلمة)"
#     elif grade == 'G1':
#         return "قصيرة (من 120 إلى 180 كلمة)"
#     elif grade == 'G2':
#         return "متوسطة القصر (من 200 إلى 300 كلمة)"
#     elif grade == 'G3':
#         return "متوسطة (من 300 إلى 450 كلمة)"
#     elif grade == 'G4':
#         return "متوسطة الطول (من 450 إلى 600 كلمة)"
#     elif grade == 'G5':
#         return "طويلة (من 600 إلى 800 كلمة)"
#     elif grade == 'G6':
#         return "طويلة جداً (من 800 إلى 1000 كلمة)"
#     else:
#         return "متوسطة (حوالي 150 كلمة)"

# def extract_story_and_mode(full_response: str):
#     modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
#     found_mode = "TILTZ" 
    
#     clean_response = full_response.strip()
#     matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
#     if matches:
#         found_mode = matches[-1]
#         story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
#         return story_part, found_mode
    
#     return clean_response, found_mode

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

# def translate_answer_to_context(answer: str):
#     answer = answer.upper().strip()
#     if "LEFT" in answer:
#         return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
#     elif "RIGHT" in answer:
#         return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
#     elif "FRONT" in answer:
#         return "الطفل قام بإمالة المكعب للأمام (اختار التقدم أو الهجوم)."
#     elif "BACK" in answer:
#         return "الطفل قام بإمالة المكعب للخلف (اختار التراجع أو الدفاع)."
#     elif "SHAKE" in answer:
#         return "الطفل قام بهز المكعب بقوة."
#     else:
#         return f"الطفل قام باختيار: {answer}"

# # --- التحديث هنا: إضافة مثال للحركة الأمامية/الخلفية لتعليم النموذج ---
# FEW_SHOT_EXAMPLES = [
#     {
#         "role": "user", 
#         "content": "ابدأ القصة. الطفل: أحمد، 5 سنوات. الموضوع: الفضاء."
#     },
#     {
#         "role": "assistant",
#         "content": "كان يا ما كان، في محطة فضاء بعيدة، يعيش رائد فضاء شجاع اسمه أحمد. كان أحمد يحب النظر للنجوم اللامعة. وفجأة، رأى كوكباً غريباً يلمع بألوان قوس قزح! أسرع أحمد لمركبته الفضائية، لكنه وجد الباب مغلقاً ويحتاج لقوة لفتحه. هل يمكنك مساعدة أحمد في فتح الباب؟ هيا، قم بهز المكعب بقوة ليفتح الباب! [SHAKE]"
#     },
#     {
#         "role": "user",
#         "content": "اكمل القصة. الطفل قام بـ: هز المكعب."
#     },
#     {
#         "role": "assistant",
#         "content": "رائع! فتح الباب بقوة وانطلق أحمد بمركبته نحو الكوكب الملون. عندما اقترب، وجد طريقين: طريق مليء بالنجوم المتلألئة لليمين، وطريق فيه نيازك سريعة لليسار. ساعد أحمد في القيادة. هل نذهب لليمين نحو النجوم أم لليسار نحو النيازك؟ قم بإمالة المكعب لليمين أو اليسار لاختيار الطريق. [TILTZ]"
#     },
#     {
#         "role": "user",
#         "content": "اكمل القصة. الطفل قام بـ: إمالة المكعب لليمين."
#     },
#     {
#         # مثال جديد لتعليم النموذج استخدام TILTY (أمام/خلف)
#         "role": "assistant",
#         "content": "يا لها من رحلة مذهلة! وصل أحمد إلى حقل النجوم اللامعة. وفجأة ظهر وحش فضائي ودود أمامه! هل يتقدم أحمد لمصافحة الوحش (أمام) أم يتراجع للخلف ليراقبه من بعيد (خلف)؟ أمل المكعب للأمام للتقدم أو للخلف للتراجع! [TILTY]"
#     }
# ]

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row
#     story_length_prompt = get_story_length_for_grade(grade)
#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
    
#     # --- التحديث هنا: تعليمات صارمة جداً بخصوص الحركات ---
#     system_prompt = (
#         "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال. أسلوبك مشوق وبسيط."
#         "قوانين صارمة جداً للاستجابة:\n"
#         "1. اسرد القصة بالعربية الفصحى السهلة واستخدم اسم الطفل دائماً.\n"
#         "2. في نهاية كل رد، اطلب من الطفل *حصراً* تحريك المكعب للمتابعة.\n"
#         "3. الممنوعات: لا تطلب من الطفل القفز، الركض، أو التصفيق. التفاعل يكون بالمكعب فقط.\n"
#         "4. أنواع التفاعل المسموحة:\n"
#         "   - للاختيار بين شيئين (مثل طريقين): اطلب إمالة المكعب (يمين/يسار) واستخدم [TILTZ].\n"
#         "   - للتقدم/التراجع أو الهجوم/الدفاع: اطلب إمالة المكعب (أمام/خلف) واستخدم [TILTY].\n"
#         "   - للأكشن والطاقة: اطلب هز المكعب واستخدم [SHAKE].\n"
#         "5. يجب أن تذكر الحركة المطلوبة بوضوح في النص (مثلاً: 'أمل المكعب للأمام أو الخلف').\n"
#         "6. اختم الرد فوراً بالتاق المناسب."
#     )
    
#     user_task_prompt = (
#         f"معلومات الطفل: {child_info}\n"
#         f"نوع القصة: {genre}. تفاصيل: {description}.\n"
#         f"اكتب بداية القصة ({story_length_prompt}).\n"
#         "انهِ الفقرة بسؤال يطلب حركة بالمكعب (يمين/يسار، أمام/خلف، أو هز). لا تطلب القفز."
#     )

#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES) 
#     messages.append({"role": "user", "content": user_task_prompt})

#     print("🔄 [OpenAI] Start Story...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.7
#     )
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None))
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     print(f"🎧 [Audio] Generating part 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, 
#         "audio_url": audio_url,
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade)

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     child_action_desc = translate_answer_to_context(answer)

#     # --- التحديث هنا: تكرار التعليمات الصارمة في كل دور ---
#     system_prompt = (
#         f"أنت 'كيوبي'، راوي قصص. الطفل المستمع: {name}, {age} سنوات.\n" 
#         "قواعد هامة:\n"
#         "1. التزم بسياق القصة الحالي.\n"
#         "2. التفاعل يكون حصراً عن طريق المكعب (لا تطلب القفز أو الركض).\n"
#         "3. اطلب بوضوح: إمالة لليمين/اليسار [TILTZ]، أو إمالة للأمام/الخلف [TILTY]، أو هز المكعب [SHAKE].\n"
#         "4. اذكر نوع الإمالة المطلوبة (أمام/خلف) بوضوح في النص."
#     )

#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES) 
#     messages.append({"role": "assistant", "content": old_story}) 
    
#     if turns >= max_turns:
#         instruction = (
#             f"الطفل قام بـ: {child_action_desc}\n"
#             f"هذه هي النهاية. اكتب خاتمة سعيدة ({story_length_prompt}).\n"
#             "يجب أن ينتهي النص بـ [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"الحدث السابق: {child_action_desc}\n"
#             f"اكمل القصة بحدث جديد ({story_length_prompt}).\n"
#             "1. تفاعل مع حركة الطفل.\n"
#             "2. اختم بسؤال يتطلب حركة مكعب جديدة (حدد الحركة: أمام/خلف أو يمين/يسار أو هز).\n"
#             "3. ضع التاق المناسب: [SHAKE] أو [TILTZ] أو [TILTY]."
#         )
#         finished = False
        
#     messages.append({"role": "user", "content": instruction})

#     print(f"🔄 [OpenAI] Continue Turn {turns}...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.7
#     )
    
#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] Generating Turn {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part,
#         "audio_url": audio_url,
#         "story_end": finished,
#         "required_move": question_mode
#     }








import os
import re
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio

chat_router = APIRouter()

# تأكد من أن مفتاح API الخاص بك يعمل بشكل صحيح
client = OpenAI(api_key="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")

# تخزين بيانات الأدوار للقصص النشطة
story_turns = {}

def get_story_config(grade_level: str):
    """
    تحديد إعدادات القصة (عدد الأدوار + كلمات كل دور) بناءً على الصف الدراسي (Grade Level)
    وفقاً للجدول المعياري.
    """
    grade = grade_level.upper().strip()
    
    # القيم المستنتجة من الجدول (Total Words / Estimated Turns)
    if grade == 'KG':
        # Total: 70-100 words
        return {"max_turns": 3, "words_per_turn": "حوالي 70-100 كلمة (بسيط جداً)"}
    
    elif grade == 'G1':
        # Total: 120-180 words
        return {"max_turns": 4, "words_per_turn": "حوالي 120-180 كلمة (جمل قصيرة)"}
    
    elif grade == 'G2':
        # Total: 200-300 words
        return {"max_turns": 4, "words_per_turn": "حوالي 200-300 كلمة"}
    
    elif grade == 'G3':
        # Total: 300-450 words
        return {"max_turns": 5, "words_per_turn": "حوالي 300-450 كلمة"}
    
    elif grade == 'G4':
        # Total: 450-600 words
        return {"max_turns": 5, "words_per_turn": "حوالي 450-600 كلمة (أوصاف أطول)"}
    
    elif grade == 'G5':
        # Total: 600-800 words
        return {"max_turns": 6, "words_per_turn": "حوالي 600-800 كلمة"}
    
    elif grade == 'G6':
        # Total: 800-1000 words
        return {"max_turns": 7, "words_per_turn": "حوالي 800-1000 كلمة (أفكار مجردة)"}
    
    else:
        # Default (Fallback)
        return {"max_turns": 5, "words_per_turn": "حوالي 80 كلمة"}

def extract_story_and_mode(full_response: str):
    modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
    found_mode = "TILTZ" # الافتراضي
    
    clean_response = full_response.strip()
    matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
    if matches:
        found_mode = matches[-1]
        story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
        return story_part, found_mode
    
    return clean_response, found_mode

def translate_answer_to_context(answer: str):
    answer = answer.upper().strip()
    if "LEFT" in answer:
        return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
    elif "RIGHT" in answer:
        return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
    elif "FRONT" in answer:
        return "الطفل قام بإمالة المكعب للأمام (اختار التقدم الامام)."
    elif "BACK" in answer:
        return "الطفل قام بإمالة المكعب للخلف (اختار التراجع الخلف)."
    elif "SHAKE" in answer:
        return "الطفل قام بهز المكعب بقوة."
    else:
        return f"الطفل قام باختيار: {answer}"

# أمثلة لتعليم النموذج (Few-Shot) - تم تحديثها لتدعم الحركات المطلوبة فقط
FEW_SHOT_EXAMPLES = [
    {
        "role": "user", 
        "content": "ابدأ القصة. الطفل: أحمد، 5 سنوات (KG). الموضوع: الفضاء."
    },
    {
        "role": "assistant",
        "content": "كان يا ما كان، رائد فضاء صغير اسمه أحمد. ركب صاروخه الفضي وانطلق بسرعة! وفجأة، رأى باب المحطة مغلقاً. يحتاج أحمد لقوتك ليفتحه. هل تساعده؟ هيا، هز المكعب بقوة ليفتح الباب! [SHAKE]"
    },
    {
        "role": "user",
        "content": "اكمل القصة. الطفل قام بـ: هز المكعب."
    },
    {
        "role": "assistant",
        "content": "أحسنت يا بطل! فتح الباب وانطلق أحمد للفضاء. أمامه الآن كوكبان: كوكب أحمر لليمين، وكوكب أزرق لليسار. أين نذهب؟ أمل المكعب لليمين للكوكب الأحمر أو لليسار للكوكب الأزرق! [TILTZ]"
    },
    {
        "role": "user",
        "content": "اكمل القصة. الطفل قام بـ: إمالة المكعب لليمين."
    },
    {
        "role": "assistant",
        "content": "وصل أحمد للكوكب الأحمر ووجد كائناً فضائياً لطيفاً! هل يقترب منه (أمام) أم يبتعد قليلاً (خلف)؟ أمل المكعب للأمام للسلام عليه أو للخلف للمراقبة! [TILTY]"
    }
]

@chat_router.post("/start/")
def start_story(
    request: Request,
    userID: int = Form(...),
    childID: int = Form(...),
    genre: str = Form(...),
    description: str = Form(...)
):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
    
    name, age, gender, grade = row
    
    # 1. جلب الإعدادات بناءً على الـ Grade
    config = get_story_config(grade)
    max_turns = config["max_turns"]
    words_per_turn = config["words_per_turn"]
    
    child_info = f"الطفل اسمه {name}، عمره {age}، الصف الدراسي {grade}."
    
    system_prompt = (
        "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال. أسلوبك مشوق وبسيط."
        "قوانين صارمة جداً للاستجابة:\n"
        "1. اسرد القصة بالعربية الفصحى السهلة واستخدم اسم الطفل دائماً.\n"
        "2. في نهاية كل رد، اطلب من الطفل *حصراً* تحريك المكعب للمتابعة.\n"
        "3. الممنوعات: لا تطلب من الطفل القفز، الركض، أو التصفيق. التفاعل يكون بالمكعب فقط.\n"
        "4. أنواع التفاعل المسموحة:\n"
        "   - للاختيار بين شيئين (مثل طريقين): اطلب إمالة المكعب (يمين/يسار) واستخدم [TILTZ].\n"
        "   - للتقدم/التراجع أو الهجوم/الدفاع: اطلب إمالة المكعب (أمام/خلف) واستخدم [TILTY].\n"
        "   - للأكشن والطاقة: اطلب هز المكعب واستخدم [SHAKE].\n"
        "5. يجب أن تذكر الحركة المطلوبة بوضوح في النص (مثلاً: 'أمل المكعب للأمام أو الخلف').\n"
        "6. اختم الرد فوراً بالتاق المناسب."
    )
    

    user_task_prompt = (
        f"معلومات الطفل: {child_info}\n"
        f"نوع القصة: {genre}. تفاصيل: {description}.\n"
        f"اكتب بداية القصة (الطول المطلوب: {words_per_turn}).\n"
       "انهِ الفقرة بسؤال يطلب حركة بالمكعب (يمين/يسار، أمام/خلف، أو هز). "
    )

    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(FEW_SHOT_EXAMPLES)
    messages.append({"role": "user", "content": user_task_prompt})

    print(f"🔄 [OpenAI] Start Story (Grade: {grade}, Turns: {max_turns})...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.6
    )
    
    full_response_text = response.choices[0].message.content
    first_part, question_mode = extract_story_and_mode(full_response_text)

    c.execute("""
        INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (userID, genre, description, user_task_prompt, first_part, None))
    conn.commit()
    story_id = c.lastrowid
    conn.close()

    # تخزين عدد الأدوار المحسوب بناءً على الـ Grade
    story_turns[story_id] = {"turns": 1, "max_turns": max_turns}
    
    print(f"🎧 [Audio] Generating part 1...")
    audio_path = generate_audio(first_part, userID, story_id, turn=1)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

    return {
        "storyID": story_id, 
        "childID": childID, 
        "text": first_part, 
        "audio_url": audio_url,
        "story_end": False,
        "required_move": question_mode
    }

@chat_router.post("/continue/")
def continue_story(
    request: Request,
    storyID: int = Form(...),
    userID: int = Form(...),
    childID: int = Form(...),
    answer: str = Form(...)
):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    
    c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
    row = c.fetchone()
    if not row:
        conn.close()
        raise HTTPException(status_code=404, detail="Story not found")
    old_story = row[0]

    c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
    child_row = c.fetchone()
    if not child_row:
        conn.close()
        raise HTTPException(status_code=404, detail="Child not found")
        
    name, age, gender, grade = child_row
    
    # 2. إعادة جلب الإعدادات للتأكد (أو الاعتماد على story_turns إذا كانت محفوظة في الذاكرة)
    config = get_story_config(grade)
    default_max_turns = config["max_turns"]
    words_per_turn = config["words_per_turn"]

    # إدارة الأدوار
    if storyID not in story_turns:
        # في حال إعادة تشغيل السيرفر وضياع الذاكرة، نعيد الحساب
        story_turns[storyID] = {"turns": 1, "max_turns": default_max_turns}
        
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    turns, max_turns = turns_info["turns"], turns_info["max_turns"]

    child_action_desc = translate_answer_to_context(answer)

    system_prompt = (
        f"أنت 'كيوبي'، راوي قصص. الطفل: {name}, {age} سنوات.\n" 
        "قواعد هامة:\n"
        "1. التزم بسياق القصة ولا تكرر المقدمة ولا قصه ال EXAMPLE.\n"
        "2. التفاعل يكون حصراً بالمكعب (تجنب طلب القفز أو الركض).\n"
        "3. الأسئلة تكون: إمالة لليمين/اليسار [TILTZ]، إمالة للأمام/الخلف [TILTY]، هز [SHAKE].\n"
        "4. اذكر الحركة بوضوح في السؤال."
    )


    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(FEW_SHOT_EXAMPLES) 
    messages.append({"role": "assistant", "content": old_story}) 
    
    if turns >= max_turns:
        instruction = (
            f"الطفل قام بـ: {child_action_desc}\n"
            f"لقد وصلنا للنهاية (الدور {turns} من {max_turns}).\n"
            f"اكتب خاتمة جميلة للقصة (الطول: {words_per_turn}).\n"
            "يجب أن ينتهي النص بـ [FINISH] فقط."
        )
        finished = True
    else:
        instruction = (
            f"الحدث السابق: {child_action_desc}\n"
            f"اكمل القصة بحدث جديد (الدور {turns} من {max_turns}). الطول: {words_per_turn}.\n"
            "1. تفاعل مع حركة الطفل.\n"
            "2. اختم بسؤال يتطلب خياراً جديداً بالمكعب (مثال: 'للهرب أمل للأمام، للاختباء أمل للخلف').\n"
            "3. ضع التاق المناسب: [SHAKE] أو [TILTZ] أو [TILTY]."
        )
        finished = False
        
    messages.append({"role": "user", "content": instruction})

    print(f"🔄 [OpenAI] Continue Turn {turns}/{max_turns}...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=messages,
        temperature=0.6
    )
    
    full_response_text = response.choices[0].message.content
    new_part, question_mode = extract_story_and_mode(full_response_text)
    
    if finished:
        question_mode = "FINISH"

    updated_story = old_story + "\n\n" + new_part
    c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
    conn.commit()
    conn.close()

    print(f"🎧 [Audio] Generating Turn {turns}...")
    audio_path = generate_audio(new_part, userID, storyID, turn=turns)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

    return {
        "storyID": storyID, 
        "childID": childID, 
        "text": new_part,
        "audio_url": audio_url,
        "story_end": finished,
        "required_move": question_mode
    }










# import os
# import re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio

# chat_router = APIRouter()

# # يفضل دائماً استخدام متغيرات البيئة للمفاتيح السرية، لكن أبقيتها كما طلبت لعدم تخريب الكود
# client = OpenAI(api_key="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")

# # تخزين بيانات الأدوار للقصص النشطة
# story_turns = {}

# def get_story_config(grade_level: str):
#     """
#     تحديد إعدادات القصة بناءً على الصف الدراسي (Grade Level) وفقاً للمعايير الجديدة.
#     يتم حساب عدد الكلمات لكل دور بناءً على الطول الإجمالي المقسم على عدد الأدوار.
#     """
#     grade = grade_level.upper().strip()
    
#     if grade == 'KG':
#         # العمر 4-5 | الطول الكلي 70-100 كلمة | المدة 1-2 دقيقة
#         return {
#             "max_turns": 3,
#             "words_per_turn": "حوالي 25-35 كلمة (جمل قصيرة وبسيطة جداً)",
#             "skills": "التركيز على التعرف على الأشياء وتذكر حدث واحد (Identifying objects and recalling a single event).",
#             "question_style": "أسئلة تذكر وتمييز (Recall and Recognition)."
#         }
    
#     elif grade == 'G1':
#         # العمر 6 | الطول الكلي 120-180 كلمة | المدة 2-3 دقيقة
#         return {
#             "max_turns": 4,
#             "words_per_turn": "حوالي 30-45 كلمة (جمل قصيرة)",
#             "skills": "فهم الجمل القصيرة وترتيب حدثين متتاليين (Understanding short sentences and sequencing two events).",
#             "question_style": "أسئلة فهم مباشر (Direct Understanding)."
#         }
    
#     elif grade == 'G2':
#         # العمر 7 | الطول الكلي 200-300 كلمة | المدة 3-4 دقيقة
#         return {
#             "max_turns": 4,
#             "words_per_turn": "حوالي 50-75 كلمة (علاقات سبب ونتيجة بسيطة)",
#             "skills": "التركيز على علاقات السبب والنتيجة البسيطة (Simple cause-effect relationships).",
#             "question_style": "أسئلة لماذا وماذا حدث (Why or What happened)."
#         }
    
#     elif grade == 'G3':
#         # العمر 8 | الطول الكلي 300-450 كلمة | المدة 4-5 دقيقة
#         return {
#             "max_turns": 5,
#             "words_per_turn": "حوالي 60-90 كلمة (حبكة بسيطة)",
#             "skills": "متابعة حبكة بسيطة واستنتاجات مباشرة (Following simple plots and making direct inferences).",
#             "question_style": "استنتاج بسيط (Simple Inference)."
#         }
    
#     elif grade == 'G4':
#         # العمر 9 | الطول الكلي 450-600 كلمة | المدة 5-6 دقيقة
#         return {
#             "max_turns": 5,
#             "words_per_turn": "حوالي 90-120 كلمة (أوصاف أطول)",
#             "skills": "فهم الأوصاف الأطول ومقارنة الشخصيات (Understanding longer descriptions and comparing characters).",
#             "question_style": "أسئلة المقارنة والكيفية (Comparison and 'How' questions)."
#         }
    
#     elif grade == 'G5':
#         # العمر 10 | الطول الكلي 600-800 كلمة | المدة 6-7 دقيقة
#         return {
#             "max_turns": 6,
#             "words_per_turn": "حوالي 100-135 كلمة (استنتاج وربط أحداث)",
#             "skills": "استنتاج الأفكار الرئيسية وربط الأحداث (Inferring main ideas and connecting events).",
#             "question_style": "أسئلة مفتوحة (Open-ended)."
#         }
    
#     elif grade == 'G6':
#         # العمر 11-12 | الطول الكلي 800-1000 كلمة | المدة 7-8 دقيقة
#         return {
#             "max_turns": 7,
#             "words_per_turn": "حوالي 115-145 كلمة (أفكار مجردة ومعقدة)",
#             "skills": "فهم القصص متعددة الأحداث والأفكار المجردة (Comprehending multi-event stories and abstract ideas).",
#             "question_style": "استنتاج متقدم (Advanced Inference)."
#         }
    
#     else:
#         # Default (Fallback)
#         return {
#             "max_turns": 5,
#             "words_per_turn": "حوالي 60-80 كلمة",
#             "skills": "قصة تفاعلية عامة.",
#             "question_style": "أسئلة عامة."
#         }

# def extract_story_and_mode(full_response: str):
#     modes = ["TILTZ", "TILTY", "SHAKE", "FINISH"]
#     found_mode = "TILTZ" # الافتراضي
    
#     clean_response = full_response.strip()
#     matches = re.findall(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", clean_response.upper())
    
#     if matches:
#         found_mode = matches[-1]
#         story_part = re.sub(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]", "", clean_response).strip()
#         return story_part, found_mode
    
#     return clean_response, found_mode

# def translate_answer_to_context(answer: str):
#     answer = answer.upper().strip()
#     if "LEFT" in answer:
#         return "الطفل قام بإمالة المكعب لليسار (اختار المسار الأيسر)."
#     elif "RIGHT" in answer:
#         return "الطفل قام بإمالة المكعب لليمين (اختار المسار الأيمن)."
#     elif "FRONT" in answer:
#         return "الطفل قام بإمالة المكعب للأمام (اختار التقدم أو الهجوم)."
#     elif "BACK" in answer:
#         return "الطفل قام بإمالة المكعب للخلف (اختار التراجع أو الدفاع)."
#     elif "SHAKE" in answer:
#         return "الطفل قام بهز المكعب بقوة."
#     else:
#         return f"الطفل قام باختيار: {answer}"

# # أمثلة لتعليم النموذج (Few-Shot)
# FEW_SHOT_EXAMPLES = [
#     {
#         "role": "user", 
#         "content": "ابدأ القصة. الطفل: أحمد، 5 سنوات (KG). الموضوع: الفضاء."
#     },
#     {
#         "role": "assistant",
#         "content": "كان يا ما كان، رائد فضاء صغير اسمه أحمد. ركب صاروخه الفضي وانطلق بسرعة! وفجأة، رأى باب المحطة مغلقاً. يحتاج أحمد لقوتك ليفتحه. هل تساعده؟ هيا، هز المكعب بقوة ليفتح الباب! [SHAKE]"
#     },
#     {
#         "role": "user",
#         "content": "اكمل القصة. الطفل قام بـ: هز المكعب."
#     },
#     {
#         "role": "assistant",
#         "content": "أحسنت يا بطل! فتح الباب وانطلق أحمد للفضاء. أمامه الآن كوكبان: كوكب أحمر لليمين، وكوكب أزرق لليسار. أين نذهب؟ أمل المكعب لليمين للكوكب الأحمر أو لليسار للكوكب الأزرق! [TILTZ]"
#     },
#     {
#         "role": "user",
#         "content": "اكمل القصة. الطفل قام بـ: إمالة المكعب لليمين."
#     },
#     {
#         "role": "assistant",
#         "content": "وصل أحمد للكوكب الأحمر ووجد كائناً فضائياً لطيفاً! هل يقترب منه (أمام) أم يبتعد قليلاً (خلف)؟ أمل المكعب للأمام للسلام عليه أو للخلف للمراقبة! [TILTY]"
#     }
# ]

# @chat_router.post("/start/")
# def start_story(
#     request: Request,
#     userID: int = Form(...),
#     childID: int = Form(...),
#     genre: str = Form(...),
#     description: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row
    
#     # 1. جلب الإعدادات بناءً على الـ Grade
#     config = get_story_config(grade)
#     max_turns = config["max_turns"]
#     words_per_turn = config["words_per_turn"]
#     skills_focus = config["skills"]
#     question_style = config["question_style"]
    
#     child_info = f"الطفل اسمه {name}، عمره {age}، الصف الدراسي {grade}."
    
#     system_prompt = (
#         "أنت 'كيوبي'، راوي قصص تفاعلية للأطفال. أسلوبك مشوق وبسيط."
#         "قوانين صارمة جداً للاستجابة:\n"
#         "1. اسرد القصة بالعربية الفصحى السهلة واستخدم اسم الطفل دائماً.\n"
#         "2. في نهاية كل رد، اطلب من الطفل *حصراً* تحريك المكعب للمتابعة.\n"
#         "3. الممنوعات: لا تطلب من الطفل القفز، الركض، أو التصفيق. التفاعل يكون بالمكعب فقط.\n"
#         "4. أنواع التفاعل المسموحة:\n"
#         "   - للاختيار بين شيئين (مثل طريقين): اطلب إمالة المكعب (يمين/يسار) واستخدم [TILTZ].\n"
#         "   - للتقدم/التراجع أو الهجوم/الدفاع: اطلب إمالة المكعب (أمام/خلف) واستخدم [TILTY].\n"
#         "   - للأكشن والطاقة: اطلب هز المكعب واستخدم [SHAKE].\n"
#         "5. يجب أن تذكر الحركة المطلوبة بوضوح في النص (مثلاً: 'أمل المكعب للأمام أو الخلف').\n"
#         "6. اختم الرد فوراً بالتاق المناسب."
#     )
    
    
#     user_task_prompt = (
#         f"معلومات الطفل: {child_info}\n"
#         f"نوع القصة: {genre}. تفاصيل: {description}.\n"
#         f"المهارات المستهدفة (Key Skills): {skills_focus}\n"
#         f"نمط الأسئلة (Questions): {question_style}\n"
#         f"اكتب بداية القصة (الطول المطلوب لهذا الرد: {words_per_turn}).\n"
#         "انهِ الفقرة بسؤال يوافق نمط الأسئلة المطلوب ويطلب حركة بالمكعب."
#     )

#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES)
#     messages.append({"role": "user", "content": user_task_prompt})

#     print(f"🔄 [OpenAI] Start Story (Grade: {grade}, Turns: {max_turns})...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.7
#     )
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None))
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     # تخزين عدد الأدوار
#     story_turns[story_id] = {"turns": 1, "max_turns": max_turns}
    
#     print(f"🎧 [Audio] Generating part 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, 
#         "audio_url": audio_url,
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...)
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
    
#     # 2. إعادة جلب الإعدادات لضمان السياق في كل دور
#     config = get_story_config(grade)
#     default_max_turns = config["max_turns"]
#     words_per_turn = config["words_per_turn"]
#     skills_focus = config["skills"]
#     question_style = config["question_style"]

#     # إدارة الأدوار
#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": default_max_turns}
        
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     child_action_desc = translate_answer_to_context(answer)

#     system_prompt = (
#         f"أنت 'كيوبي'، راوي قصص. الطفل: {name}, {age} سنوات.\n" 
#         "قواعد هامة:\n"
#         "1. التزم بسياق القصة ولا تكرر المقدمة.\n"
#         "2. التفاعل يكون حصراً بالمكعب.\n"
#         "3. الأسئلة تكون: إمالة لليمين/اليسار [TILTZ]، إمالة للأمام/الخلف [TILTY]، هز [SHAKE].\n"
#         "4. اذكر الحركة بوضوح في السؤال."
#     )

#     messages = [{"role": "system", "content": system_prompt}]
#     messages.extend(FEW_SHOT_EXAMPLES) 
#     messages.append({"role": "assistant", "content": old_story}) 
    
#     if turns >= max_turns:
#         instruction = (
#             f"الطفل قام بـ: {child_action_desc}\n"
#             f"لقد وصلنا للنهاية (الدور {turns} من {max_turns}).\n"
#             f"المهارات المستهدفة: {skills_focus}\n"
#             f"اكتب خاتمة جميلة للقصة (الطول: {words_per_turn}).\n"
#             "يجب أن ينتهي النص بـ [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"الحدث السابق: {child_action_desc}\n"
#             f"المهارات المستهدفة: {skills_focus}\n"
#             f"نمط الأسئلة: {question_style}\n"
#             f"اكمل القصة بحدث جديد (الدور {turns} من {max_turns}). الطول المطلوب: {words_per_turn}.\n"
#             "1. تفاعل مع حركة الطفل.\n"
#             "2. اختم بسؤال يتطلب خياراً جديداً بالمكعب (مثال: 'للهرب أمل للأمام، للاختباء أمل للخلف').\n"
#             "3. ضع التاق المناسب: [SHAKE] أو [TILTZ] أو [TILTY]."
#         )
#         finished = False
        
#     messages.append({"role": "user", "content": instruction})

#     print(f"🔄 [OpenAI] Continue Turn {turns}/{max_turns}...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=messages,
#         temperature=0.2
#     )
    
#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] Generating Turn {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part, 
#         "audio_url": audio_url,
#         "story_end": finished,
#         "required_move": question_mode
#     }