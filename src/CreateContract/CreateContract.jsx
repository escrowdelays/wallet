import React, { useState, useEffect } from 'react';
import { Button,  TextField, InputAdornment} from '@mui/material';
import IconButton from '@mui/material/IconButton';
import CloseIcon from '@mui/icons-material/Close';
import Slider from '@mui/material/Slider';


import ConnectAlert from '../Components/ConnectAlert';
import { useStoreHook } from '../Store/Hooks';
import { errors } from '../Store/Store';






function CreateContract() {


  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState("");
  const [deposit, setDeposit] = useState("");
  const [interval, setInterval] = useState(30);

  const {selectedAccount,balance, startGame} = useStoreHook()

  const handleClickOpen = () => {
    setOpen(true);
  };
  const handleClose = () => {
    setOpen(false);
  };

  

  const clearDeposit = () => {
    setDeposit(0);
  };

  const changeDeposit = (event) => {
   
    const value = event.target.value;
    // Проверяем, что value содержит только цифры (пустая строка тоже допускается)
    if (value === "" || /^[0-9]+$/.test(value)) {
      setDeposit(Number(value));
    }
  };


  const clearAmount = () => {
    setAmount(0);
  };

  const changeAmount = (event) => {
    const value = event.target.value;
    // Проверяем, что value содержит только цифры (пустая строка тоже допускается)
    if (value === "" || /^[0-9]+$/.test(value)) {
      setAmount(Number(value));
    }
  };

  const handleSliderChange = (event, newValue) => {
    setInterval(newValue);
  };



  


  return (
        
<>
    <div style={{display:'flex', justifyContent:'center', flexDirection:'column', alignItems:'center'}} >

      <h1 style={styles.timeHeader}>
        AMOUNT USDT
      </h1>
      <div style={{display:'flex',  justifyContent:'space-between', alignItems:'center', margin: '10px', width:'calc(100% - 32px)', maxWidth:'500px' }}>
        <TextField
          variant="outlined"
          value={amount}
          onChange={changeAmount}
          sx={{
            color:'antiquewhite',
            width: 'calc(100% - 32px)',
            marginLeft: '16px',
            marginRight: '16px',
            '& .MuiInputLabel-shrink': {
              backgroundColor: 'antiquewhite',  // фон как у инпута
              padding: '0 4px',                 // чтобы фон не прилипал к тексту
              borderRadius: '2px', 
              border:'1px solid black'
            },
            '& .MuiInputAdornment-root': {
              color: 'antiquewhite', // Цвет крестика
            },
            '& .MuiInputLabel-root': {
              color: 'antiquewhite', // Цвет метки
            },
            '& .MuiInputBase-input': {
              color: 'antiquewhite', // Цвет текста
              fontSize: '11px',

            },
            '& .MuiOutlinedInput-root': {
              backgroundColor: 'black', // Цвет фона

            },

            '& .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite', // Цвет рамки
              

            },
            '&:hover .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite',


            },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite',

            },
            '& .MuiInputLabel-root': {
              color: 'antiquewhite',  // обычный цвет
            },
            '& .MuiInputLabel-root.Mui-focused': {
              color: 'black',  // цвет при фокусе — такой же
            },
          }}
          InputProps={{
            endAdornment: (
              amount > 0 ? (
                <InputAdornment position="end">
                  <IconButton sx={{ color: 'antiquewhite' }}   onClick={clearAmount} size="small">
                  <CloseIcon />
             </IconButton>
                </InputAdornment>
              ) : null
            ),
          }}
        />
      </div>

      <h1 style={styles.timeHeader}>
         REGULAR DEPOSIT
      </h1>
      <div style={{display:'flex',  justifyContent:'space-between', alignItems:'center', margin: '10px', width:'calc(100% - 32px)', maxWidth:'500px' }}>
        <TextField
          variant="outlined"
          value={deposit}
          onChange={changeDeposit}
          sx={{
            color:'antiquewhite',
            width: 'calc(100% - 32px)',
            marginLeft: '16px',
            marginRight: '16px',
            '& .MuiInputLabel-shrink': {
              backgroundColor: 'antiquewhite',  // фон как у инпута
              padding: '0 4px',                 // чтобы фон не прилипал к тексту
              borderRadius: '2px', 
              border:'1px solid antiquewhite'
            },
            '& .MuiInputAdornment-root': {
              color: 'antiquewhite', // Цвет крестика
            },
            '& .MuiInputLabel-root': {
              color: 'antiquewhite', // Цвет метки
            },
            '& .MuiInputBase-input': {
              color: 'antiquewhite', // Цвет текста
              fontSize: '11px',

            },
            '& .MuiOutlinedInput-root': {
              backgroundColor: 'black', // Цвет фона

            },

            '& .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite', // Цвет рамки
              

            },
            '&:hover .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite',


            },
            '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
              borderColor: 'antiquewhite',

            },
            '& .MuiInputLabel-root': {
              color: 'antiquewhite',  // обычный цвет
            },
            '& .MuiInputLabel-root.Mui-focused': {
              color: 'antiquewhite',  // цвет при фокусе — такой же
            },
          }}
          InputProps={{
            endAdornment: (
              deposit > 1 ? (
                <InputAdornment position="end">
                  <IconButton  sx={{ color: 'antiquewhite' }} onClick={clearDeposit} size="small" >
                  <CloseIcon />  
                  </IconButton>
                </InputAdornment >
              ) : null
            ),
          }}
        />
      </div>



      </div>





        <h1 style={styles.timeHeader}>
        TIME INTERVAL: {interval} {interval>1 ? 'DAYS':'DAY'}
        </h1>
        <div style={{display:'flex', justifyContent:'center', alignItems:'center', marginRight: '30px', marginLeft:'30px' }}>

      <Slider
        onChange={handleSliderChange}
        value={interval}
        color="primary"
        min={1}
        max={366}
        sx={{
          maxWidth: '500px',

        }}
        
      />

        </div>

        <div style={{display:'flex', justifyContent:'center', marginTop:'30px'}}>

        {selectedAccount ? 
          (balance >= deposit && deposit < amount && deposit!=0 && amount!=0 ?
              <Button
                variant="contained"
                color="primary"
                onClick={() =>  startGame(amount, deposit, interval) } // передаём параметры через стрелочную функцию
                sx={{ margin: '10px' }}
              >
                create 
              </Button>
          :
          
          <ConnectAlert errors={{...errors, 'smallBalance': balance < 1, 'depositAmount': deposit >= amount, "depositZero":deposit==0, "amountZero": amount==0}} knopka={"contained"} text={'create'}/>)


        :
        <ConnectAlert errors={{...errors, 'connect':true}} knopka={"contained"} text={'create'}/>
      }



        </div>
        </>
  );
}

const styles = {
  timeHeader:{
    textAlign:'center',
    color:'antiquewhite',
    fontSize:'1em',
    fontWeight: 100,
    marginTop:'30px',
    marginBottom:'10px',
    fontWeight: 500
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
  addresPlayer:{
    color: 'antiquewhite',
    fontSize: '11px',
    textAlign: 'left',
    fontWeight: 'lighter',
    whiteSpace: 'nowrap', 
    overflow: 'hidden',  
    textOverflow: 'ellipsis',
  }
};


export default CreateContract;
