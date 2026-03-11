function add(a, b) {
    return a + b;
}

console.log(add(1, 2));

//투두리스트 가져오는 함수 만들기, 저장하는 함수 만들기, 삭제하는 함수 만들기, 수정하는 함수 만들기
function getTodoList() {
    const todoListStr = localStorage.getItem('todoList');
    if (!todoListStr) {
        return [];
    }
    try {
        const parsed = JSON.parse(todoListStr);
        if (Array.isArray(parsed)) {
            return parsed;
        } else {
            // 올바른 배열이 아니면 빈 배열 반환
            return [];
        }
    } catch (e) {
        // 파싱 에러 시 빈 배열 반환
        return [];
    }
}

function saveTodoList(todoList) {
    if (!Array.isArray(todoList)) {
        throw new Error('todoList must be an array');
    }
    localStorage.setItem('todoList', JSON.stringify(todoList));
}

function deleteTodoList(id) {
    if (typeof id === 'undefined' || id === null) {
        throw new Error('id is required for deleteTodoList');
    }
    const todoList = getTodoList();
    const filtered = todoList.filter((item) => item.id !== id);
    if (filtered.length === todoList.length) return false;
    saveTodoList(filtered);
    return true;
}

function updateTodoList(id, updates) {
    if (typeof id === 'undefined' || id === null) {
        throw new Error('id is required for updateTodoList');
    }
    const todoList = getTodoList();
    const index = todoList.findIndex((item) => item.id === id);
    if (index === -1) return false;
    if (typeof updates === 'object' && updates !== null) {
        todoList[index] = { ...todoList[index], ...updates };
    }
    saveTodoList(todoList);
    return true;
}