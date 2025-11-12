
# import os
# import re # (1) استيراد مكتبة re
# from fastapi import APIRouter, HTTPException, Form, Request
# import sqlite3
# from db import DB_NAME
# from openai import OpenAI
# from audio import generate_audio
# from fastapi.staticfiles import StaticFiles


# chat_router = APIRouter()
# client = OpenAI(
#  api_key="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"
# )

# # in-memory turn tracking (reset on server restart)
# story_turns = {}

# # (2) دالة تحديد طول القصة بناءً على القريد
# def get_story_length_for_grade(grade_level: str):
#     if grade_level == 'KG':
#         return "قصيرة جداً (حوالي 70 إلى 100 كلمة)"
#     elif grade_level == 'G1':
#         return "قصيرة (حوالي 120 إلى 180 كلمة)"
#     elif grade_level == 'G2':
#         return "متوسطة القصر (حوالي 200 إلى 300 كلمة)"
#     elif grade_level == 'G3':
#         return "متوسطة (حوالي 300 إلى 450 كلمة)"
#     elif grade_level == 'G4':
#         return "متوسطة الطول (حوالي 450 إلى 600 كلمة)"
#     elif grade_level == 'G5':
#         return "طويلة (حوالي 600 إلى 800 كلمة)"
#     elif grade_level == 'G6':
#         return "طويلة جداً (حوالي 800 إلى 1000 كلمة)"
#     else:
#         return "متوسطة (حوالي 200 كلمة)" # قيمة افتراضية

# # (3) دالة فصل النص عن أمر الحركة
# def extract_story_and_mode(full_response: str):
#     # البحث عن كود الحركة في نهاية النص
#     mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
    
#     if mode_match:
#         mode = mode_match.group(1) # استخراج الكود (مثل "TILTZ")
#         story_part = full_response[:mode_match.start()].strip() # استخراج النص قبله
#         return story_part, mode
#     else:
#         # إذا لم يجد الكود، يرجع النص كاملاً ويفترض سؤال افتراضي
#         return full_response.strip(), "TILTZ" 

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

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
#     # (4) جلب القريد مع باقي بيانات الطفل
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
    
#     name, age, gender, grade = row # (5) تم إضافة grade
    
#     # (6) تحديد طول القصة بناءً على القريد
#     story_length_prompt = get_story_length_for_grade(grade)

#     child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
#     prefs = f"النوع: {genre}؛ وصف: {description}."
    
#     # (7) تحديث البرومبت (الأمر) لـ GPT
#     system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {child_info} {prefs} "
#         f"مهم جداً: يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
#         "ابدأ القصة مباشرة. يجب أن ينتهي هذا الجزء بسؤال تفاعلي يطلب من الطفل الاختيار بين ثلاث مسارين (مثل: يمين أو يسار، أو أمام أو خلف)او (هز)."
#         " اسأل سؤالاً مهم جدا جدا ان يكون متواجد لازم ،الأهم: في نهاية ردك، يجب أن تكتب كود الحركة المطلوب بين قوسين مربعين. اختر واحداً فقط:"
#         "[TILTZ] (للاختيار بين يمين ويسار)"
#         "[TILTY] (للاختيار بين أمام وخلف)"
#         "[SHAKE] (للاختيارات العشوائية مثل 'هز المكعب لترى ما سيحدث')"
#         "مثال للرد: '...وجد أمامه بابين، باب أحمر على اليمين وباب أزرق على اليسار. أي باب سيختار؟' [TILTZ]"
#     )


#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[{"role": "system", "content": system_prompt}]
#     )
#     full_response_text = response.choices[0].message.content

#     # (8) فصل النص عن الكود
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, "auto-generated", first_part, None)) # نحفظ الجزء الأول فقط
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"

#     # (9) إرسال question_mode للفرونت إند
#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "part": first_part, 
#         "audio_path": audio_url, 
#         "finished": False,
#         "question_mode": question_mode # <-- هذا ضروري للفرونت إند
#     }
    
# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...) # (10) استقبال الجواب من المكعب (مثل "RIGHT")
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     # (11) جلب القريد والعمر مجدداً
#     c.execute("SELECT name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     child_row = c.fetchone()
#     if not child_row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Child not found")
        
#     name, age, gender, grade = child_row
#     story_length_prompt = get_story_length_for_grade(grade) # (12) تحديد الطول

#     if storyID not in story_turns:
#         story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
#     turns_info = story_turns[storyID]
#     turns_info["turns"] += 1
#     turns, max_turns = turns_info["turns"], turns_info["max_turns"]

#     if turns >= max_turns:
#         # (13) برومبت الإنهاء
#         system_prompt = (
#             f"سياق القصة حتى الآن:\n{old_story}\n\n"
#             f"الطفل ({name}, عمره {age}, مستواه {grade}) اختار: \"{answer}\".\n"
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "انهِ القصة الآن بخاتمة سعيدة ومناسبة. لا تضع أي أسئلة جديدة."
#             "في نهاية الرد، اكتب [FINISH] فقط."
#         )
#         finished = True
#     else:
#         # (14) برومبت الاستمرار
#         system_prompt = (
#             f"سياق القصة حتى الآن:\n{old_story}\n\n"
#             f"الطفل ({name}, عمره {age}, مستواه {grade}) اختار: \"{answer}\".\n"
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً مهم جدا جدا ان يكون متواجد لازم جديداً بخيارين (يمين/يسار أو أمام/خلف)."
#             "في نهاية ردك، يجب أن تكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#         )
#         finished = False

#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[{"role": "system", "content": system_prompt}]
#     )
#     full_response_text = response.choices[0].message.content

#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part

#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     # (التعديل الصحيح لـ line 346 in backend/chat.py)
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "part": new_part, 
#         "audio_path": audio_url, 
#         "finished": finished,
#         "question_mode": question_mode
#     }

# (ملف backend/chat.py كامل ومعدل)










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
#     # (ملاحظة: مفتاح الـ API هذا ظاهر للجميع، الأفضل تغييره بعدين)
#     api_key="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"
# )

# # هذا المتغير لتتبع عدد الأدوار (يتم تصفيره عند إعادة تشغيل السيرفر)
# story_turns = {}

# def get_story_length_for_grade(grade_level: str):
#     if grade_level == 'KG':
#         return "قصيرة جداً (جملتين إلى 3 جمل)"
#     elif grade_level in ['G1', 'G2']:
#         return "قصيرة (3 إلى 4 جمل)"
#     elif grade_level in ['G3', 'G4']:
#         return "متوسطة (4 إلى 5 جمل)"
#     else:
#         return "متوسطة (4 إلى 5 جمل)"

# def extract_story_and_mode(full_response: str):
#     mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
#     if mode_match:
#         mode = mode_match.group(1)
#         story_part = full_response[:mode_match.start()].strip()
#         return story_part, mode
#     else:
#         # إذا لم يجد الكود، يفترض أن القصة انتهت (أو خطأ)
#         return full_response.strip(), "FINISH"

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

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
#     prefs = f"النوع: {genre}؛ وصف: {description}."
    
#     # --- (1) تعديل: فصلنا الأوامر ---
#     # هذا يحدد "شخصية" الذكاء الاصطناعي
#     system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {child_info} {prefs}"
#     )
    
#     # هذا هو "الأمر" الأول
#     user_task_prompt = (
#         f"ابدأ القصة مباشرة. يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
#         "يجب أن ينتهي هذا الجزء بسؤال تفاعلي يطلب من الطفل الاختيار بين مسارين (مثل: يمين أو يسار، أو أمام أو خلف)."
#         "الأهم: في نهاية ردك، يجب أن تكتب كود الحركة المطلوب بين قوسين مربعين. اختر واحداً فقط:"
#         "[TILTZ] (للاختيار بين يمين ويسار)"
#         "[TILTY] (للاختيار بين أمام وخلف)"
#         "[SHAKE] (للاختيارات العشوائية مثل 'هز المكعب لترى ما سيحدث')"
#     )

#     print("🔄 [OpenAI] إرسال طلب بدء القصة...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": user_task_prompt} # <-- (2) إرسال الأمر كـ "user"
#         ]
#     )
#     print("✅ [OpenAI] استلم الرد الأول.")
    
#     full_response_text = response.choices[0].message.content
#     first_part, question_mode = extract_story_and_mode(full_response_text)

#     # (3) حفظ الجزء الأول فقط في الداتابيس (وليس الأمر)
#     c.execute("""
#         INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
#         VALUES (?, ?, ?, ?, ?, ?)
#     """, (userID, genre, description, user_task_prompt, first_part, None)) # <-- حفظنا النص النظيف
#     conn.commit()
#     story_id = c.lastrowid
#     conn.close()

#     story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
#     print(f"🎧 [Audio] بدء توليد الصوت للجزء 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "part": first_part, 
#         "audio_path": audio_url, 
#         "finished": False,
#         "question_mode": question_mode
#     }
    
# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...) # (مثل "RIGHT" أو "LEFT")
# ):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
    
#     # (1) جلب القصة *الكاملة* حتى الآن
#     c.execute("SELECT generated_story FROM stories WHERE storyID=? AND userID=?", (storyID, userID))
#     row = c.fetchone()
#     if not row:
#         conn.close()
#         raise HTTPException(status_code=404, detail="Story not found")
#     old_story = row[0]

#     # (2) جلب بيانات الطفل
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

#     # --- (3) تعديل كبير: بناء سجل المحادثة (هذا هو الحل للسرعة) ---
    
#     # الشخصية (System)
#     base_system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {name}, عمره {age}, مستواه {grade}."
#     )
    
#     # بناء سجل المحادثة
#     message_history = [
#         {"role": "system", "content": base_system_prompt},
#         # القصة حتى الآن (كلام المساعد)
#         {"role": "assistant", "content": old_story},
#         # رد الطفل (User)
#         {"role": "user", "content": f"الطفل اختار: \"{answer}\""}
#     ]

#     # الأمر الجديد (System)
#     if turns >= max_turns:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "انهِ القصة الآن بخاتمة سعيدة ومناسبة. لا تضع أي أسئلة جديدة."
#             "في نهاية الرد، اكتب [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً جديداً بخيارين (يمين/يسار أو أمام/خلف)."
#             "في نهاية ردك، يجب أن تكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#         )
#         finished = False
        
#     message_history.append({"role": "system", "content": instruction})
#     # --- نهاية التعديل ---

#     print(f"🔄 [OpenAI] إرسال طلب تكملة القصة (Turn {turns})...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=message_history  # <-- (4) استخدام سجل المحادثة الجديد
#     )
#     print(f"✅ [OpenAI] استلم الرد (Turn {turns}).")

#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     # (5) تحديث القصة في الداتابيس بالنص الجديد *فقط*
#     # هذا مهم: old_story + new_part
#     updated_story = old_story + "\n\n" + new_part

#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] بدء توليد الصوت للجزء {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     # انتبه هنا: كان عندك خطأ بسيط (story_id بدلاً من storyID)
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "part": new_part, 
#         "audio_path": audio_url, 
#         "finished": finished,
#         "question_mode": question_mode
#     }
# (ملف backend/chat.py كامل ومعدل للسرعة)















#/////////////////////////////////////////////////////////////////////////////////////////////
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
#         return "قصيرة جداً (جملتين إلى 3 جمل)"
#     elif grade_level in ['G1', 'G2']:
#         return "قصيرة (3 إلى 4 جمل)"
#     else:
#         return "متوسطة (4 إلى 5 جمل)"

# def extract_story_and_mode(full_response: str):
#     mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
#     if mode_match:
#         mode = mode_match.group(1)
#         story_part = full_response[:mode_match.start()].strip()
#         return story_part, mode
#     return full_response.strip(), "FINISH"

# def get_max_turns(age: int):
#     if age <= 5: return 3
#     elif age <= 8: return 5
#     return 7

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
#     prefs = f"النوع: {genre}؛ وصف: {description}."
    
#     # (1) هذا هو الأسلوب "السريع" (سجل محادثة)
#     system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
#         f"معلومات الطفل: {child_info} {prefs}"
#     )
#     user_task_prompt = (
#         f"ابدأ القصة مباشرة. يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
#         "يجب أن ينتهي هذا الجزء بسؤال تفاعلي يطلب من الطفل الاختيار بين مسارين."
#         "في نهاية ردك، اكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#     )

#     print("🔄 [OpenAI] إرسال طلب بدء القصة...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=[
#             {"role": "system", "content": system_prompt},
#             {"role": "user", "content": user_task_prompt} # <-- إرسال الأمر كـ "user"
#         ]
#     )
#     print("✅ [OpenAI] استلم الرد الأول.")
    
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
    
#     print(f"🎧 [Audio] بدء توليد الصوت للجزء 1...")
#     audio_path = generate_audio(first_part, userID, story_id, turn=1)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     # (مهم جداً) الكود هذا يرجع كل شيء الفلاتر يحتاجه من أول مرة
#     # هذا يحل مشكلة الـ replay/
#     return {
#         "storyID": story_id, 
#         "childID": childID, 
#         "text": first_part, # (تأكد أن الاسم "text")
#         "audio_url": audio_url, # (تأكد أن الاسم "audio_url")
#         "story_end": False,
#         "required_move": question_mode
#     }

# @chat_router.post("/continue/")
# def continue_story(
#     request: Request,
#     storyID: int = Form(...),
#     userID: int = Form(...),
#     childID: int = Form(...),
#     answer: str = Form(...) # (مثل "RIGHT" أو "LEFT")
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

#     # --- (هذا هو الحل للسرعة) ---
#     base_system_prompt = (
#         "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة."
#         f"معلومات الطفل: {name}, عمره {age}, مستواه {grade}."
#     )
    
#     # بناء سجل المحادثة (أسرع بكثير)
#     message_history = [
#         {"role": "system", "content": base_system_prompt},
#         {"role": "assistant", "content": old_story}, # <-- القصة حتى الآن (كلام المساعد)
#         {"role": "user", "content": f"الطفل اختار: \"{answer}\""} # <-- رد الطفل (User)
#     ]

#     if turns >= max_turns:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "انهِ القصة الآن بخاتمة سعيدة. لا تضع أي أسئلة جديدة."
#             "في نهاية الرد، اكتب [FINISH] فقط."
#         )
#         finished = True
#     else:
#         instruction = (
#             f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
#             "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً جديداً بخيارين."
#             "في نهاية ردك، اكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
#         )
#         finished = False
        
#     message_history.append({"role": "system", "content": instruction}) # <-- الأمر الجديد
#     # --- نهاية التعديل ---

#     print(f"🔄 [OpenAI] إرسال طلب تكملة القصة (Turn {turns})...")
#     response = client.chat.completions.create(
#         model="gpt-4o-mini",
#         messages=message_history  # <-- (2) استخدام سجل المحادثة الجديد (هذا هو السر)
#     )
#     print(f"✅ [OpenAI] استلم الرد (Turn {turns}).")

#     full_response_text = response.choices[0].message.content
#     new_part, question_mode = extract_story_and_mode(full_response_text)
    
#     if finished:
#         question_mode = "FINISH"

#     updated_story = old_story + "\n\n" + new_part
#     c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
#     conn.commit()
#     conn.close()

#     print(f"🎧 [Audio] بدء توليد الصوت للجزء {turns}...")
#     audio_path = generate_audio(new_part, userID, storyID, turn=turns)
#     base_url = str(request.base_url).rstrip("/")
#     audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"
#     print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

#     return {
#         "storyID": storyID, 
#         "childID": childID, 
#         "text": new_part, # (تأكد أن الاسم "text")
#         "audio_url": audio_url, # (تأكد أن الاسم "audio_url")
#         "story_end": finished,
#         "required_move": question_mode
#     }
    
    # (ملف backend/chat.py كامل ومعدل)

import os
import re
from fastapi import APIRouter, HTTPException, Form, Request
import sqlite3
from db import DB_NAME
from openai import OpenAI
from audio import generate_audio
from fastapi.staticfiles import StaticFiles

chat_router = APIRouter()
client = OpenAI(
    # (ملاحظة: هذا المفتاح ظاهر للجميع، الأفضل تغييره لاحقاً)
    api_key="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"
)

# تتبع الأدوار
story_turns = {}

# --- (1. تعديل: رجعنا الدالة حقتك للقريد) ---
def get_story_length_for_grade(grade_level: str):
    if grade_level == 'KG':
        return "قصيرة جداً (حوالي 70 إلى 100 كلمة)"
    elif grade_level == 'G1':
        return "قصيرة (حوالي 120 إلى 180 كلمة)"
    elif grade_level == 'G2':
        return "متوسطة القصر (حوالي 200 إلى 300 كلمة)"
    elif grade_level == 'G3':
        return "متوسطة (حوالي 300 إلى 450 كلمة)"
    elif grade_level == 'G4':
        return "متوسطة الطول (حوالي 450 إلى 600 كلمة)"
    elif grade_level == 'G5':
        return "طويلة (حوالي 600 إلى 800 كلمة)"
    elif grade_level == 'G6':
        return "طويلة جداً (حوالي 800 إلى 1000 كلمة)"
    else:
        return "متوسطة (حوالي 200 كلمة)" # قيمة افتراضية
# --- نهاية التعديل 1 ---

def extract_story_and_mode(full_response: str):
    mode_match = re.search(r"\[(TILTZ|TILTY|SHAKE|FINISH)\]$", full_response.strip().upper())
    if mode_match:
        mode = mode_match.group(1)
        story_part = full_response[:mode_match.start()].strip()
        return story_part, mode
    else:
        # (إذا نسي الذكاء الاصطناعي السؤال، نفرض سؤال افتراضي)
        print("⚠️ [Warning] OpenAI did not return a move code. Defaulting to TILTZ.")
        return full_response.strip(), "TILTZ" 

def get_max_turns(age: int):
    if age <= 5: return 3
    elif age <= 8: return 5
    return 7

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
    story_length_prompt = get_story_length_for_grade(grade) # <-- (يستخدم الدالة الجديدة)
    child_info = f"الطفل اسمه {name}، عمره {age}، جنسه {gender}، ومستواه الدراسي {grade}."
    prefs = f"النوع: {genre}؛ وصف: {description}."
    
    system_prompt = (
        "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة. اتبع نبرة لطيفة وواضحة."
        f"معلومات الطفل: {child_info} {prefs}"
    )
    
    # --- (2. تعديل: شددنا على ضرورة وجود السؤال) ---
    user_task_prompt = (
        f"ابدأ القصة مباشرة. يجب أن يكون طول هذا الجزء من القصة {story_length_prompt}."
        "مهم جداً: يجب أن ينتهي هذا الجزء بسؤال تفاعلي. هذا السؤال إلزامي (لازم يكون موجود)."
        "السؤال يطلب من الطفل الاختيار بين مسارين (مثل: يمين أو يسار، أو أمام أو خلف) أو (هز)."
        "الأهم: في نهاية ردك، يجب أن تكتب كود الحركة المطلوب بين قوسين مربعين. اختر واحداً فقط:"
        "[TILTZ] (للاختيار بين يمين ويسار)"
        "[TILTY] (للاختيار بين أمام وخلف)"
        "[SHAKE] (للاختيارات العشوائية مثل 'هز المكعب لترى ما سيحدث')"
        "مثال للرد: '...وجد أمامه بابين، باب أحمر على اليمين وباب أزرق على اليسار. أي باب سيختار؟' [TILTZ]"
    )
    # --- نهاية التعديل 2 ---

    print("🔄 [OpenAI] إرسال طلب بدء القصة...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_task_prompt}
        ]
    )
    print("✅ [OpenAI] استلم الرد الأول.")
    
    full_response_text = response.choices[0].message.content
    first_part, question_mode = extract_story_and_mode(full_response_text)

    c.execute("""
        INSERT INTO stories (userID, genre, preferences, prompt, generated_story, audio_path)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (userID, genre, description, user_task_prompt, first_part, None))
    conn.commit()
    story_id = c.lastrowid
    conn.close()

    story_turns[story_id] = {"turns": 1, "max_turns": get_max_turns(age)}
    
    print(f"🎧 [Audio] بدء توليد الصوت للجزء 1...")
    audio_path = generate_audio(first_part, userID, story_id, turn=1)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{story_id}/{os.path.basename(audio_path)}"
    print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

    # (مهم جداً) هذا الرد متوافق مع story_progress.dart
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
    story_length_prompt = get_story_length_for_grade(grade) # <-- (يستخدم الدالة الجديدة)

    if storyID not in story_turns:
        story_turns[storyID] = {"turns": 1, "max_turns": get_max_turns(age)}
    turns_info = story_turns[storyID]
    turns_info["turns"] += 1
    turns, max_turns = turns_info["turns"], turns_info["max_turns"]

    # --- (هذا هو الكود السريع: بناء سجل المحادثة) ---
    base_system_prompt = (
        "أنت راوي قصص تفاعلية للأطفال باللغة العربية الفصحى المبسطة."
        f"معلومات الطفل: {name}, عمره {age}, مستواه {grade}."
    )
    
    message_history = [
        {"role": "system", "content": base_system_prompt},
        {"role": "assistant", "content": old_story},
        {"role": "user", "content": f"الطفل اختار: \"{answer}\""}
    ]

    # --- (3. تعديل: شددنا على ضرورة وجود السؤال) ---
    if turns >= max_turns:
        instruction = (
            f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
            "انهِ القصة الآن بخاتمة سعيدة ومناسبة. لا تضع أي أسئلة جديدة."
            "في نهاية الرد، اكتب [FINISH] فقط."
        )
        finished = True
    else:
        instruction = (
            f"مهم جداً: اكمل القصة بجزء {story_length_prompt}."
            "أكمل القصة بفقرة جديدة، ثم اسأل سؤالاً جديداً. هذا السؤال إلزامي (لازم يكون موجود)."
            "السؤال يجب أن يكون بخيارين (يمين/يسار أو أمام/خلف) أو (هز)."
            "في نهاية ردك، يجب أن تكتب كود الحركة المطلوب: [TILTZ] أو [TILTY] أو [SHAKE]."
        )
        finished = False
    # --- نهاية التعديل 3 ---
        
    message_history.append({"role": "system", "content": instruction})

    print(f"🔄 [OpenAI] إرسال طلب تكملة القصة (Turn {turns})...")
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=message_history
    )
    print(f"✅ [OpenAI] استلم الرد (Turn {turns}).")

    full_response_text = response.choices[0].message.content
    new_part, question_mode = extract_story_and_mode(full_response_text)
    
    if finished:
        question_mode = "FINISH"

    updated_story = old_story + "\n\n" + new_part
    c.execute("UPDATE stories SET generated_story=? WHERE storyID=?", (updated_story, storyID))
    conn.commit()
    conn.close()

    print(f"🎧 [Audio] بدء توليد الصوت للجزء {turns}...")
    audio_path = generate_audio(new_part, userID, storyID, turn=turns)
    base_url = str(request.base_url).rstrip("/")
    audio_url = f"{base_url}/audio_files/{userID}/{storyID}/{os.path.basename(audio_path)}"
    print(f"✅ [Audio] تم توليد الصوت: {audio_url}")

    # (مهم جداً) هذا الرد متوافق مع story_progress.dart
    return {
        "storyID": storyID, 
        "childID": childID, 
        "text": new_part,
        "audio_url": audio_url,
        "story_end": finished,
        "required_move": question_mode
    }