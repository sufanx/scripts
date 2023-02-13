let body = $response.body;
let obj = JSON.parse(body);

if (obj.code === 0) {
    let questions = obj.data.question;
    console.log(questions);
    questions.forEach((question) => {
        question.answer.forEach((answer) => {
            let answerIndex = atob(answer);
            // switch(answer){
            //     case "QQ==" :
            //         answerIndex="A";
            //         break;
            //     case "Qg==" :
            //         answerIndex="B";
            //         break;
            //     case "Qw==" :
            //         answerIndex="C";
            //         break;
            //     default :
            //         answerIndex="D";
            // }
            question.option.forEach((option) => {
                if (option.index === answerIndex) {
                    option.detail = "Y " + option.detail;
                }
            });
        });
    });
}

body = JSON.stringify(obj);

$done(body);
