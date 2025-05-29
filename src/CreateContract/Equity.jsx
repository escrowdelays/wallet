
import Paper from '@mui/material/Paper';
import React, { useState, useRef, useEffect } from 'react';
import { Dialog, DialogActions, DialogContent, DialogTitle, Button, createTheme, ThemeProvider,  TextField, Fab, InputAdornment} from '@mui/material';



import { useStoreHook } from '../Store/Hooks';
import CountdownTimer from './Timer';
import ConnectAlert from '../Components/ConnectAlert';
import { errors } from '../Store/Store';



function Equity() {

  const [status, setStatus]= useState({pre:false, active:false, end:true})
  const {game, sendDeposit, clearGame} = useStoreHook()



  return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', color: 'antiquewhite', flexDirection: 'column' }}>
          <p style={{ fontSize: 20, margin: 0, marginBottom: 10, textAlign:'left' }}>AMOUNT: {game.targetAmount} USDT</p>
          <p style={{ fontSize: 20, margin: 0, marginBottom: 10, textAlign:'left'   }}>TOTAL: {game.totalDeposits} USDT</p>
          <p style={{ fontSize: 20, margin: 0, marginBottom: 10 }}>REGULAR: {game.depositAmount} USDT</p>
          <p style={{ fontSize: 20, margin: 0, marginBottom: 10 }}>INTERVAL: {game.interval} days</p>


          {status.pre && <p style={{margin:0, marginTop: '20px'}}>Old interval</p>}
          {status.active && <p style={{margin:0, marginTop: '20px'}}>Actual interval</p>}
          {status.end  && game.totalDeposits == game.targetAmount && <h1>YOU WIN</h1>}
          {status.end  && game.totalDeposits != game.targetAmount && <h1>YOU LOSE</h1>}



          <CountdownTimer setStatus={setStatus} />
          {status.end &&  <Button variant='contained' onClick={()=>{clearGame()}}>create new</Button>}
          {status.pre && <ConnectAlert knopka={"contained"} text={'send deposit'}  errors={{...errors, 'interval':true}}  />}
          {status.active && <Button variant='contained' onClick={()=>{sendDeposit()}}>send deposit</Button>}
          
      
          
        </div>


  );
  
}

const styles = {
  timeHeader:{
    textAlign:'center',
    color:'antiquewhite',
    fontSize:'1em',
    fontWeight: 100,
    marginTop:'30px',
    marginBottom:'10px'
  },

  header:{
    color:'antiquewhite',
    fontSize:'4em',
    textAlign:'center',
    marginTop:'5vh',
    marginBottom:0,
    lineHeight: 0.8,
  },
  headerBottom:{
    color:'antiquewhite',
    fontSize:'2.3em',
    textAlign:'center',
    lineHeight: 1,
    margin:0,
  },
  domen:{
    textAlign:'center',
    color:'antiquewhite',
    fontSize:'1em',
    fontWeight: 100,
    marginBottom: '50px',
    marginTop: 5

  },
  rules:{
    color:'antiquewhite',
    fontSize:'0.8em',
    fontWeight: 100,
    margin:'10px',
  },

  container: {
    width: '100vw',
    height: '100vh',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    position: 'relative',
    background: 'black',
  },
  border: {
    position: 'absolute',
    top: 10,
    left: 10,
    right: 10,
    bottom: 10,
    border: '3px solid antiquewhite',
    background: 'black',
    overflowY: 'auto  '
  },
};


export default Equity;
