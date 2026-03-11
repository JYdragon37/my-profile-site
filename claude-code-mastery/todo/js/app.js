// 투두 앱 메인 로직
class TodoApp {
    constructor() {
        this.currentFilter = 'all';
        this.editingId = null;
        this.init();
    }

    init() {
        this.cacheElements();
        this.bindEvents();
        this.render();
    }

    cacheElements() {
        this.todoForm = document.getElementById('todoForm');
        this.todoInput = document.getElementById('todoInput');
        this.totalCount = document.getElementById('totalCount');
        this.completedCount = document.getElementById('completedCount');
        this.progressCount = document.getElementById('progressCount');
        this.completionRate = document.getElementById('completionRate');
        this.todoListContainer = document.getElementById('todoListContainer');
        this.emptyState = document.getElementById('emptyState');
        this.filterBtns = document.querySelectorAll('.filter-btn');
        this.editModal = document.getElementById('editModal');
        this.editForm = document.getElementById('editForm');
        this.editInput = document.getElementById('editInput');
        this.cancelEditBtn = document.getElementById('cancelEdit');
    }

    bindEvents() {
        this.todoForm.addEventListener('submit', (e) => this.handleAdd(e));
        this.filterBtns.forEach(btn => {
            btn.addEventListener('click', (e) => this.handleFilter(e));
        });
        this.editForm.addEventListener('submit', (e) => this.handleEditSubmit(e));
        this.cancelEditBtn.addEventListener('click', () => this.closeEditModal());
        this.editModal.addEventListener('click', (e) => {
            if (e.target === this.editModal) this.closeEditModal();
        });
    }

    handleAdd(e) {
        e.preventDefault();
        const title = this.todoInput.value.trim();
        if (!title) {
            alert('할 일 내용을 입력해주세요!');
            return;
        }
        TodoStorage.addItem(title);
        this.todoInput.value = '';
        this.todoInput.focus();
        this.render();
    }

    handleFilter(e) {
        this.currentFilter = e.target.dataset.filter;
        this.filterBtns.forEach(btn => btn.classList.remove('active'));
        e.target.classList.add('active');
        this.render();
    }

    handleToggle(id) {
        TodoStorage.toggleComplete(id);
        this.render();
    }

    openEditModal(id, currentTitle) {
        this.editingId = id;
        this.editInput.value = currentTitle;
        this.editModal.classList.remove('hidden');
        this.editModal.classList.add('flex');
        this.editInput.focus();
    }

    closeEditModal() {
        this.editingId = null;
        this.editInput.value = '';
        this.editModal.classList.add('hidden');
        this.editModal.classList.remove('flex');
    }

    handleEditSubmit(e) {
        e.preventDefault();
        const newTitle = this.editInput.value.trim();
        if (!newTitle) {
            alert('할 일 내용을 입력해주세요!');
            return;
        }
        if (this.editingId) {
            TodoStorage.updateItem(this.editingId, newTitle);
            this.closeEditModal();
            this.render();
        }
    }

    handleDelete(id, title) {
        if (confirm(`"${title}"\n정말 삭제하시겠습니까?`)) {
            TodoStorage.deleteItem(id);
            this.render();
        }
    }

    updateStats() {
        const stats = TodoStorage.getStats();
        this.totalCount.textContent = stats.total;
        this.completedCount.textContent = stats.completed;
        this.progressCount.textContent = stats.progress;
        this.completionRate.textContent = `${stats.completionRate}%`;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    createTodoItemHTML(item) {
        const completedClass = item.completed ? 'line-through text-gray-400' : 'text-gray-800';
        const checkIcon = item.completed ? '✓' : '';
        const checkboxClass = item.completed
            ? 'bg-green-500 border-green-500 text-white'
            : 'bg-white border-gray-300';
        const escapedTitle = this.escapeHtml(item.title);
        const escapedTitleForAttr = escapedTitle.replace(/'/g, "\\'");

        return `
            <div class="todo-item bg-white rounded-lg shadow-md p-4 flex items-center gap-3 hover:shadow-lg transition-shadow">
                <button
                    class="flex-shrink-0 w-6 h-6 rounded border-2 flex items-center justify-center ${checkboxClass} transition-all hover:scale-110"
                    onclick="todoApp.handleToggle('${item.id}')"
                >
                    <span class="text-sm font-bold">${checkIcon}</span>
                </button>
                <div class="flex-1">
                    <p class="text-lg ${completedClass} break-words">${escapedTitle}</p>
                    <p class="text-xs text-gray-400 mt-1">
                        ${new Date(item.createdAt).toLocaleDateString('ko-KR')} 생성
                        ${item.completedAt ? ` · ${new Date(item.completedAt).toLocaleDateString('ko-KR')} 완료` : ''}
                    </p>
                </div>
                <div class="flex gap-2 flex-shrink-0">
                    <button
                        class="px-3 py-1 bg-blue-100 text-blue-600 rounded hover:bg-blue-200 transition-colors text-sm font-medium"
                        onclick="todoApp.openEditModal('${item.id}', '${escapedTitleForAttr}')"
                    >
                        수정
                    </button>
                    <button
                        class="px-3 py-1 bg-red-100 text-red-600 rounded hover:bg-red-200 transition-colors text-sm font-medium"
                        onclick="todoApp.handleDelete('${item.id}', '${escapedTitleForAttr}')"
                    >
                        삭제
                    </button>
                </div>
            </div>
        `;
    }

    render() {
        this.updateStats();
        const list = TodoStorage.getFilteredList(this.currentFilter);

        if (list.length === 0) {
            this.todoListContainer.innerHTML = '';
            this.emptyState.classList.remove('hidden');
            return;
        }

        this.emptyState.classList.add('hidden');
        this.todoListContainer.innerHTML = list.map(item => this.createTodoItemHTML(item)).join('');
    }
}

let todoApp;
document.addEventListener('DOMContentLoaded', () => {
    todoApp = new TodoApp();
});
