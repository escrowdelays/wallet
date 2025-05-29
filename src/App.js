import './App.css';
import React, { useState, useEffect } from 'react';
import { ThemeProvider, Fab} from '@mui/material';

import Box from '@mui/material/Box';
import About from './Components/About';

import ConnectWallet from './Components/ConnectWallet';
import CreateContract from './CreateContract/CreateContract';
import EmergencyIcon from '@mui/icons-material/Emergency'; 
import {theme} from './Components/Theme'
import textDivider from './images/2.svg'


import { useStoreHook } from './Store/Hooks';
import Equity from './CreateContract/Equity';



  

function App() {
  const [openAbout, setOpenAbout] = useState(false);
  const {selectedAccount, setNav, getGame, game}   = useStoreHook()



useEffect(() => {

getGame(selectedAccount)

}, [selectedAccount])

useEffect(() => {
    console.log(1111, game);
}, [game])

const errors = {
  "smallBalance": false,
  "connect": false,
  "turn": false,
  "smallBet":false,
  "moreTwo":false
}

  return (
    <ThemeProvider theme={theme}>
      <div style={styles.container}>
        <div style={styles.border}>
        <Box
          sx={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            overflow: 'hidden',
            '&::before': {
              content: '""',
              position: 'absolute',
              inset: 0,
              backgroundImage: `url('https://uploads-ssl.webflow.com/6340524a90d47a1821f48d2d/63d0386c50677a1ea97e2365_image.webp')`,
              backgroundPosition: 'center',
              opacity: 0.3,
              zIndex: 1,
            },
            '& > *': {
              position: 'relative',
              zIndex: 1,
            }
          }}
        >
        </Box>

          <div style={{position:'relative',zIndex:2}}>
            <div style={{display:'flex', justifyContent:'space-between'}}>
              <Fab size="small" color="primary" aria-label="add" onClick={()=>setOpenAbout(!openAbout)} sx={{
                margin:'10px'
              }} >
                <EmergencyIcon />
              </Fab>
              <ConnectWallet />
            </div>

            <About open={openAbout} setOpen={setOpenAbout}/>
            

              
              <h1 style={styles.header} className='courier-prime-regular'>
                  escrow
                  </h1>
                  <h1 style={styles.headerBottom} className='courier-prime-regular'>
                  wallet
              </h1>
              <h1 style={styles.domen}>escrowcontracts.net</h1>


              


              {
               game.intervalEndTime == 0 ? <CreateContract /> : <Equity/>     
              }
          </div>

        <div style={{display:'flex', width:'100%', justifyContent:'center'}}> 
          <img src={textDivider} alt="Logo" style={{
                  marginBottom: "15px",
                  width: "90%",
                  maxWidth: "350px"
            }}/>
        </div>


        </div>
      </div>
  </ThemeProvider>

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
nav:{
  display: 'flex',
  justifyContent:'center',
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
    fontSize:'3em',
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
    background: '#000',
  },
  border: {
    position: 'absolute',
    top: 15,
    left: 15,
    right: 15,
    bottom: 15,
    border: '3px solid antiquewhite',
    // background: "url(https://img.freepik.com/premium-photo/black-textile-fabric-closeup-macro-detail-made-into-seamless-tileable-pattern-image-width-20cm_692357-9554.jpg)",
    overflowY: 'auto',
    boxShadow: "0px 0px 20px",  
    display: 'flex',
    flexDirection:'column',
    justifyContent:'space-between'
  },
};


export default App;
