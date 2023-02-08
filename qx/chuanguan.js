/**
 * @fileoverview Example of HTTP rewrite.
 *
 * @supported Quantumult X (v1.0.5-build173)
 */

// $request, $response, $notify(title, subtitle, message), console.log(message)
// $request.scheme, $request.method, $request.url, $request.path, $request.headers
// $response.statusCode, $response.headers, $response.body
//
// $prefs is for persistent store and the data of $prefs will be cleared when Quantumult X is deleted.
// $prefs.setValueForKey(value, key), $prefs.removeValueForKey(key), $prefs.removeAllValues(). Returns true or false, value and key should be string.
// $prefs.valueForKey(key) returns value.
//
// setTimeout(function() { console.log("abc"); }, 1000);
//
// You can optional change the response headers at the same time by using $done({body: modifiedBody, headers: modifiedHeaders}); only change the response headers is not allowed for script-response-body. The modifiedHeaders can be copied and modified from $response.headers, please do not change the content length, type and encoding field.
// Response status can also be optional changed by using $done({body: modifiedBody, headers: modifiedHeaders, status: modifiedStatus}), the modifiedStatus should be like "HTTP/1.1 200 OK"

var body = $response.body;
var obj = JSON.parse(body);

if(obj.code == 0){
    var questions = obj.data.question
    console.log(questions);
    questions.forEach(question => {
        question.answer.forEach(answer=>{
            var answerIndex;
            switch(answer){
                case "QQ==" :
                    answerIndex="A";
                    break; 
                case "Qg==" :
                    answerIndex="B";
                    break; 
                case "Qw==" :
                    answerIndex="C";
                    break; 
                default :  
                    answerIndex="D";
            }
            question.option.forEach(option=>{
                if(option.index===answerIndex){
                    option.detail="Y "+option.detail
                }
            })
        })
    });
}


body = JSON.stringify(obj);

$done(body);