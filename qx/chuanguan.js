let body = $response.body;
let obj = JSON.parse(body);

if (obj.code === 0) {
    let questions = obj.data.question;
    questions.forEach((question) => {
        question.answer.forEach((answer) => {
            let answerIndex = atob(answer);
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
