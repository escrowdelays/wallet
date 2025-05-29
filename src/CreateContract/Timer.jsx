import React, { useState, useEffect } from 'react';
import { useStoreHook } from '../Store/Hooks';

const CountdownTimer = ({setStatus}) => {
  const [seconds, setSeconds] = useState(0);



  const {game, nav, setNav} = useStoreHook()



  useEffect(() => {
    const lastTime = game.intervalEndTime - Math.ceil(Date.now()/1000)
          
    if(lastTime > 0 && game.targetAmount > game.totalDeposits){
      if(lastTime - game.interval > 0){
        setStatus({pre:true, active:false, end:false})
        setSeconds(lastTime - game.interval);
      }else{
        setSeconds(lastTime)
        setStatus({pre:false, active:true, end:false})

      }
    }else{
      setSeconds(0);
      setStatus({pre:false, active:false, end:true})
    }



  }, [game]);

  useEffect(() => {
    const timer = setInterval(() => {
      setSeconds((prevSeconds) => { 
        if (prevSeconds === 0) {
          if (game.intervalEndTime - Math.ceil(Date.now()/1000) - game.interval + 10 > 0) {
            setStatus({pre:false, active:true, end:false})
            return game.interval;
          } else {
            setStatus({pre:false, active:false, end:true})
            return 0; 
          }
        }
        return prevSeconds - 1;
      });
    }, 1000);
  
    return () => clearInterval(timer);
  }, [seconds]);



  const days = Math.floor(seconds / (60 * 60 * 24));
  const hours = Math.floor((seconds % (60 * 60 * 24)) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const displaySeconds = seconds % 60;


  return (
    <div style={{ fontSize: '48px', fontWeight: 'bold', textAlign: 'center', marginBottom: '30px' }}>
      {/* Формат: DD:HH:MM:SS */}
      {`${String(days).padStart(2, '0')}:${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(displaySeconds).padStart(2, '0')}`}
    </div>
  );
};

export default CountdownTimer;
