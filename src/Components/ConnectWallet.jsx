import { NetworkErrorMessage } from "./NetworkErrorMessage"
import { Web3Provider } from '@ethersproject/providers';
import { Contract, formatEther, formatUnits } from 'ethers';
import tokenAddress from '../contracts/Token-address.json';
import tokenArtifact from '../contracts/Token.json';
import equityAddress from '../contracts/Equityaddress.json';
import equityArtifact from '../contracts/Equity.json';
import { Dialog, DialogActions, DialogContent, DialogTitle, Button, createTheme, ThemeProvider,  TextField, Fab, InputAdornment} from '@mui/material';
import React, { useState, useEffect } from 'react';
import { useStoreHook } from "../Store/Hooks";

export default function ConnectWallet() {



  const HARDHAT_NETWORK_ID = '0x7a69';
  const {
    selectedAccount,
    setSelectedAccount,
    setNetworkError,
    setProvider,
    setToken,
    setEquity,
    setBalance,
    balance
  } = useStoreHook()



  const connectWallet = async () => {


    
    try{
      if (!window.ethereum) {
        setNetworkError('Please install Metamask!')
        return;
      }

    const [selectedAddress] = await window.ethereum.request({
      method: 'eth_requestAccounts',
    });

    if (!checkNetwork()) return;

    initialize(selectedAddress);

      window.ethereum.on('accountsChanged', ([newAddress]) => {
        if (!newAddress) {
          resetState();
        } else {
          initialize(newAddress);
        }
      });

      window.ethereum.on('chainChanged', () => {
        resetState();
      });
    }catch(error){
      console.error(error)
    }
  };


  const checkNetwork = () => {    
    if (window.ethereum.chainId === HARDHAT_NETWORK_ID) {
      return true;
    }
    setNetworkError('Please connect to localhost:8545')
    return false;
  };

  const initialize = async (selectedAddress) => {
    const _provider = new Web3Provider(window.ethereum);
    const _token = new Contract(
      tokenAddress.Token,
      tokenArtifact.abi,
      _provider.getSigner()
    );
    const _Equity = new Contract(
      equityAddress.Equity,
      equityArtifact.abi,
      _provider.getSigner()
    );

    const newBalance = await _token.balanceOf(selectedAddress);
    
    
    setProvider(_provider);
    setToken(_token);
    setEquity(_Equity);
    setSelectedAccount(selectedAddress.toLowerCase());
    setBalance(Number(newBalance))


  };



  const resetState = () => {
    setSelectedAccount(null)
    setBalance(null)
    setProvider(null);
    setToken(null);
    setEquity(null);

  };

  const dismissNetworkError = () => {
    setNetworkError(null)
  };






  return (
    <>
      {/* <div>
        {networkError && (
          <NetworkErrorMessage 
            message={networkError} 
            dismiss={dismiss} 
          />
        )}
      </div> */}

      {
        !selectedAccount ?
          <Button variant="contained" color="primary" onClick={connectWallet} sx={{
            margin: '10px',
          }} >
            connect
          </Button>
        :
        
          <Button variant="contained" onClick={()=>{}}  color="primary" sx={{
            margin: '10px',
          }} >
            {balance} usdt
          </Button>
          

        }
    </>
  )
}


    