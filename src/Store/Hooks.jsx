import useStore from './Store'







export function useStoreHook() {
  const selectedAccount = useStore(state => state.selectedAccount);
  const setNetworkError = useStore(state => state.setNetworkError);
  const setSelectedAccount = useStore(state => state.setSelectedAccount);
  const setProvider = useStore(state => state.setProvider);
  const setToken = useStore(state => state.setToken);
  const setEquity = useStore(state => state.setEquity);
  const equity = useStore(state => state.equity);
  const setNav = useStore(state => state.setNav);
  const nav = useStore(state => state.nav);
  const balance = useStore(state => state.balance);
  const setBalance = useStore(state => state.setBalance);
  const setGames = useStore(state => state.setGames);
  const game = useStore(state => state.game);
  const getGame = useStore(state => state.getGame);
  const sendBet = useStore(state => state.sendBet);
  const startGame = useStore(state => state.startGame);
  const win = useStore(state => state.win);
  const sendDeposit = useStore(state => state.sendDeposit);
  const clearGame = useStore(state => state.clearGame);


    return {
      selectedAccount,
      setNetworkError,
      setSelectedAccount,
      setProvider,
      setToken,
      setEquity,
      equity,
      setNav,
      nav,
      balance,
      setBalance,
      setGames,
      startGame,
      win,
      getGame,
      sendBet,
      game,
      sendDeposit,
      clearGame

    }
  }