/**
 * LocalStorage 투두 리스트 관리
 * main.js의 getTodoList, saveTodoList 패턴을 사용
 */
const TodoStorage = {
    STORAGE_KEY: 'todoList',

    load() {
        const data = localStorage.getItem(this.STORAGE_KEY);
        if (!data) return [];
        try {
            const parsed = JSON.parse(data);
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            console.error('투두 로드 실패:', e);
            return [];
        }
    },

    save(todoList) {
        if (!Array.isArray(todoList)) {
            throw new Error('todoList must be an array');
        }
        try {
            localStorage.setItem(this.STORAGE_KEY, JSON.stringify(todoList));
            return true;
        } catch (e) {
            console.error('투두 저장 실패:', e);
            return false;
        }
    },

    addItem(title) {
        const todoList = this.load();
        const newItem = {
            id: Date.now().toString(),
            title: title.trim(),
            completed: false,
            createdAt: new Date().toISOString(),
            completedAt: null
        };
        todoList.unshift(newItem);
        this.save(todoList);
        return newItem;
    },

    updateItem(id, newTitle) {
        const todoList = this.load();
        const index = todoList.findIndex(item => item.id === id);
        if (index !== -1) {
            todoList[index].title = newTitle.trim();
            this.save(todoList);
            return true;
        }
        return false;
    },

    deleteItem(id) {
        if (typeof id === 'undefined' || id === null) {
            throw new Error('id is required for deleteItem');
        }
        const todoList = this.load();
        const filtered = todoList.filter(item => item.id !== id);
        if (filtered.length === todoList.length) return false;
        this.save(filtered);
        return true;
    },

    toggleComplete(id) {
        const todoList = this.load();
        const index = todoList.findIndex(item => item.id === id);
        if (index === -1) return false;
        todoList[index].completed = !todoList[index].completed;
        todoList[index].completedAt = todoList[index].completed
            ? new Date().toISOString()
            : null;
        this.save(todoList);
        return todoList[index].completed;
    },

    getStats() {
        const todoList = this.load();
        const total = todoList.length;
        const completed = todoList.filter(item => item.completed).length;
        const progress = total - completed;
        const completionRate = total > 0 ? Math.round((completed / total) * 100) : 0;
        return { total, completed, progress, completionRate };
    },

    getFilteredList(filter = 'all') {
        const todoList = this.load();
        switch (filter) {
            case 'active':
                return todoList.filter(item => !item.completed);
            case 'completed':
                return todoList.filter(item => item.completed);
            default:
                return todoList;
        }
    }
};
