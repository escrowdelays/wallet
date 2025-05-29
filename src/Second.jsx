import logo from './logo.svg';
import './App.css';
import Paper from '@mui/material/Paper';
import React, { useState, useRef } from 'react';
import { Dialog, DialogActions, DialogContent, DialogTitle, Button, createTheme, ThemeProvider,  TextField, Fab, InputAdornment} from '@mui/material';
// import AddIcon from '@mui/icons-material/Add';
import IconButton from '@mui/material/IconButton';
import CloseIcon from '@mui/icons-material/Close';
import AddIcon from '@mui/icons-material/Add';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import { CSSTransition, TransitionGroup } from 'react-transition-group';
import AccessAlarmIcon from '@mui/icons-material/AccessAlarm';
import HourglassEmptyIcon from '@mui/icons-material/HourglassEmpty';
import Slider from '@mui/material/Slider';
import Box from '@mui/material/Box';
import CountdownTimer from './Timer';
import AddressList from './AddressList';
const theme = createTheme({
  palette: {
    primary: {
      main: '#faebd7', // Голубой цвет для primary
    },
    secondary: {
      main: '#000', // Красный цвет для secondary
    },
  },
});






function Second() {
  const totalDaysInMs = 5 * 24 * 60 * 60 * 1000; // 5 дней в миллисекундах
  const currentTimeInMs = Date.now(); // текущее время в миллисекундах
  const [usdt,setUsdt] = useState(0);

  const usdtChange = (event) => {
    setUsdt(event.target.value);
  }

  const usdtClear = () => {
    setUsdt('');
  }

  return (

    <div style={{display:'flex',  justifyContent:'center', alignItems:'center', color:'antiquewhite',flexDirection:'column' }}>

    <h1 style={{fontSize:20,margin:0, marginBottom:10}}>Total amount: 17343 USDT</h1>
    <h1 style={{fontSize:20,margin:0, marginBottom:10}}>Last payment: 2000 USDT</h1>

    <CountdownTimer totalDaysInMs={totalDaysInMs} currentTimeInMs={currentTimeInMs} />



    <AddressList/>

<div style={{maxWidth: '300px', display:'flex', width:'calc(100% - 32px)', marginTop:30}}>
<TextField
id="outlined-number"
type="number"
label="USDT"
variant="outlined"
value={usdt}
onChange={usdtChange}
sx={{
width: 'calc(100% - 32px)',
marginLeft: '16px',
marginRight: '16px',
'& .MuiInputAdornment-root': {
color: '#faebd7',
},
'& .MuiInputLabel-root': {
color: '#faebd7',
},
'& .MuiInputBase-input': {
color: '#faebd7',
opacity: 0.3,
fontSize: '11px',
// 🔽 Убираем стрелки на Chrome, Safari, Edge
'&::-webkit-outer-spin-button': {
  WebkitAppearance: 'none',
  margin: 0,
},
'&::-webkit-inner-spin-button': {
  WebkitAppearance: 'none',
  margin: 0,
},
// 🔽 Убираем стрелки на Firefox
MozAppearance: 'textfield',
},
'& .MuiOutlinedInput-root': {
backgroundColor: '#000',
},
'& .MuiOutlinedInput-notchedOutline': {
borderColor: '#faebd7',
},
'&:hover .MuiOutlinedInput-notchedOutline': {
borderColor: '#faebd7',
},
'&.Mui-focused .MuiOutlinedInput-notchedOutline': {
borderColor: '#faebd7',
},
}}
InputProps={{
endAdornment: (
usdt > 0 ? (
  <InputAdornment position="end">
    <IconButton onClick={usdtClear} size="small">
      <CloseIcon sx={{ color: '#faebd7' }} />
    </IconButton>
  </InputAdornment>
) : null
),
}}
/>
</div>
    
          <Button variant="contained" color="primary" onClick={()=>{}} sx={{
            margin: '30px',
          }} >
            send transaction
          </Button>
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


export default Second;
