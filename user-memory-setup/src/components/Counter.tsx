// Counter.tsx
'use client';

import { useState } from 'react';

/**
 * 간단한 카운터 컴포넌트
 * 숫자를 증가/감소시킬 수 있는 기본 카운터
 */
export default function Counter() {
  const [count, setCount] = useState<number>(0);

  // 카운트 증가 함수
  const increment = () => {
    setCount(prev => prev + 1);
  };

  // 카운트 감소 함수
  const decrement = () => {
    setCount(prev => prev - 1);
  };

  // 카운트 초기화 함수
  const reset = () => {
    setCount(0);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="bg-white rounded-2xl shadow-2xl p-8 w-full max-w-md">
        <h1 className="text-3xl font-bold text-center text-gray-800 mb-8">
          카운터
        </h1>

        {/* 카운트 표시 영역 */}
        <div className="bg-gradient-to-r from-blue-500 to-indigo-600 rounded-xl p-8 mb-6">
          <p className="text-6xl font-bold text-white text-center">
            {count}
          </p>
        </div>

        {/* 버튼 그룹 */}
        <div className="flex gap-4 mb-4">
          <button
            onClick={decrement}
            className="flex-1 bg-red-500 hover:bg-red-600 text-white font-semibold py-4 px-6 rounded-lg transition-colors duration-200 active:scale-95 transform"
          >
            -1
          </button>
          <button
            onClick={increment}
            className="flex-1 bg-green-500 hover:bg-green-600 text-white font-semibold py-4 px-6 rounded-lg transition-colors duration-200 active:scale-95 transform"
          >
            +1
          </button>
        </div>

        {/* 초기화 버튼 */}
        <button
          onClick={reset}
          className="w-full bg-gray-500 hover:bg-gray-600 text-white font-semibold py-3 px-6 rounded-lg transition-colors duration-200 active:scale-95 transform"
        >
          초기화
        </button>
      </div>
    </div>
  );
}
