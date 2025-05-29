import React, { useState, useRef } from 'react';
import { Dialog, Box, DialogContent, DialogTitle, Button, createTheme, ThemeProvider,  TextField, Fab, InputAdornment, Typography} from '@mui/material';
import EmergencyIcon from '@mui/icons-material/Emergency'; 






function About({open,setOpen}) {

  const handleClose = () => {
    setOpen(false);
  };

 
  return (

      <Dialog  log open={open} onClose={handleClose} 
      sx={{
        '& .MuiDialog-paper': {
          background:"#faebd7",
          padding: '0px',
          borderRadius: '8px',
          boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.2)', // Тень для диалогового окна
          display:'flex',
          justifyContent:'flex-end',
          alignItems:'flex-end',
          
        },
        }}>
          <Box sx={{display:'flex', flexDirection:'raw', justifyContent:'space-between', width:'100%',padding:'20px', boxSizing:'border-box', paddingBottom:0}}>
            <Typography sx={{fontSize:'20px', fontWeight: 900}}>Правила контракта</Typography>
            <EmergencyIcon sx={{}} />
          </Box>
        <DialogContent>
          Вы назначаете сумму которую хотите накопить, 
          сумму регулярного депозита и интервал времени, 
          в течении которого вы должны внести депозит.
          Если вы опоздали, то теряете все что накопили.
          Переводить несколько депозитов заранее, нельзя.
          Когда накопите всю сумму, деньги вернутся на Ваш кошелек.
           
        </DialogContent>
        {/* <DialogActions>
          <Button onClick={handleClose} color="secondary">
            Применить
          </Button>
        </DialogActions> */}
      </Dialog>
        
        

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


export default About;
