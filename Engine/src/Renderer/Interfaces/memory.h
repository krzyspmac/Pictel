//
//  memory.h
//  Engine
//
//  Created by krzysp on 04/01/2022.
//

#ifndef memory_h
#define memory_h

#include "common.h"

namespace engine
{

    /**
     An abstract interface to deal with releasing object.
     During the course of the lifecycle of the game scripts
     many objects can be created. To limit the number of
     managers, those objects that do not belong to a manager
     land in a common ReleaseQueue. At the end of the script
     (or scene change) the ReleaseQueue is drained. The Queue
     should contain only those object that fit the "dangling
     in memory" criterion.
     
     Some object may `keep` the objects for longer thus preventing
     the MemoryI::ReleaseMem() function from actually releasing the object.
     */
    class MemoryI
    {
        int m_counter;
    public:
        MemoryI() : m_counter(0) { };
        virtual ~MemoryI() { };
        void Keep() {
            m_counter++;
        };
        void Release() {
            m_counter--;
            FreeMem();
            
        };
        void FreeMem() {
            if (m_counter <= 0) {
                delete this;
            }
        };
    };

    /** Keeper of the reference counter, shared amonst instances of ref_ptr of a particular
        object */
    class ref_ptr_counter
    {
        int m_counter;
    public:
        ref_ptr_counter() {
            m_counter = 1;
        }

        ~ref_ptr_counter() {
            
        };

        void Keep() { m_counter++; };

        void Release() { m_counter--; };

        int GetCounter() { return m_counter; };

        bool SafeToRelease() {
            return m_counter <= 0;
            
        };
    };

    /** A way to keep counter based, semi-manual memory management. Useful if passing
        objects via method parameters and lambdas */
    template <typename T>
    class ref_ptr
    {
        T * m_ptr;
        std::shared_ptr<ref_ptr_counter> m_counterPtr;
    public:
        ref_ptr(T* ptr) {
            m_ptr = ptr;
            m_counterPtr = std::shared_ptr<ref_ptr_counter>(new ref_ptr_counter());
        };

        ref_ptr(const ref_ptr<T>& other) {
            this->m_ptr = other.m_ptr;
            this->m_counterPtr = other.m_counterPtr;
            this->Keep();
        }

        ~ref_ptr() {
            if (m_ptr != nullptr) {
                Release();
            }
        }

        auto get() { return m_ptr; }

        auto getCounter() { return m_counterPtr.get()->GetCounter(); };

        void Keep() {
            getCounterPtr()->Keep();
        };

        void Release() {
            auto counterPtr = getCounterPtr();
            counterPtr->Release();

            if (counterPtr->SafeToRelease()) {
                FreeMem();
            }
        };

        void FreeMem() {
            if (m_ptr != nullptr) {
                delete m_ptr;
                m_ptr = nullptr;
            }
        }

        std::shared_ptr<ref_ptr<T*>> shared() {
            return std::make_shared<ref_ptr<T*>>(this);
        }

    private:
        auto getCounterPtr() { return m_counterPtr.get(); };
    };

    /**
     An abstract interface to implement a shared memory pool
     that keeps dangling objects that the game script might
     not have manually removed.
     
     The pool should be drained when there's no danger of removal
     objects in use.
     */
    class MemoryReleasePoolI
    {
    public:
        /** @private */
        virtual ~MemoryReleasePoolI() { };
        
        /**
         Store an object in the pool.
         */
        virtual void Sink(MemoryI*) = 0;
        
        /**
         Drain the pool, calling ReleaseMem on all
         members.
         */
        virtual void Drain() = 0;
    };

}; // namespace engine

#endif /* memory_h */