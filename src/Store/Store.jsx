import { create } from 'zustand'
import tokenAddress from '../contracts/Token-address.json';
import tokenArtifact from '../contracts/Token.json';
import equityAddress from '../contracts/Equityaddress.json';
import equityArtifact from '../contracts/Equity.json';

const ERROR_CODE_TX_REJECTED_BY_USER = 4001
export const errors = {
    "smallBalance": false,
    "connect": false,
    'depositAmount': false, 
    "depositZero":false, 
    "amountZero": false,
    "interval": false,
}

const _game = {
    targetAmount: 0,
    intervalEndTime:0,
    totalDeposits:0,
    depositAmount:0,
    interval:0
}

const useStore = create((set,get) => ({
    provider:null,
    setProvider: (newProvider) => set({ provider: newProvider }),
    token: null,
    setToken: (newToken) => set({ token: newToken}),
    equity: null, 
    setEquity: (newEquity) => set({ equity: newEquity}),
    nav:false, 
    setNav: (newNav) => set({ nav: newNav}),
    selectedAccount: null,
    setSelectedAccount: (x) => set({ selectedAccount: x}),
    balance: null,
    setBalance: (x) => set({ balance: x}),
    networkError:null,
    setNetworkError: (x) => set({ nav: x}),

    game:_game,
    setGame: (x) => set({ game:x }),
    clearGame:() => set({game:_game}),
    startGame: async (amount, deposit, interval) =>{

        const {token, getGame,setBalance, balance, setNav, equity, selectedAccount} = get()
        if (!token) {
            console.error('Token contract is not loaded');
            return;
        }
        if(balance <= deposit && deposit >= amount && deposit == 0 && amount == 0){
            console.log('bad data');
            return        
        } 

        console.log(amount , deposit, interval);
        
        try {
                const approveTx = await token.approve(equityAddress.Equity, deposit); 
                const approveReceipt = await approveTx.provider.waitForTransaction(approveTx.hash);
                console.log('Token approved successfully:', approveReceipt.status);
                const tx = await equity.start(deposit, amount, interval); // Отправляем транзакцию для старта игры
            
                console.log('Transaction sent, waiting for confirmation...');
    
                const receipt = await tx.provider.waitForTransaction(tx.hash); // Ожидаем завершения транзакции    
                console.log("Transaction sent");
                if (receipt.status === 1) {
                    console.log('started successfully!');
                    await getGame()
                    const newBalance = await token.balanceOf(selectedAccount)
                    setBalance(Number(newBalance))
                    setNav(false)
    
                } else {
                    console.error('Transaction failed');
                }
    
                console.log('was started');
                
    
            } catch (error) {
                if (error.code === ERROR_CODE_TX_REJECTED_BY_USER) {
                    console.log('Транзакция отклонена пользователем');
                } else {
                    console.error('Error in start:', error);
                }
            } 
    },
    getGame: async () => {
        const { equity, selectedAccount, setGame } = get()
        if (!equity || !selectedAccount) return 
        
        const _game = await equity.getUserInfo(selectedAccount)
        console.log(_game);
        
        const {targetAmount, intervalEndTime, totalDeposits, interval, depositAmount} = _game

        setGame({targetAmount:Number(targetAmount), intervalEndTime:Number(intervalEndTime), totalDeposits:Number(totalDeposits), interval:Number(interval), depositAmount:Number(depositAmount)})
    },
    sendDeposit:  async () => {
                const {token, equity, getGame, game, setBalance,selectedAccount} = get()

                try{
                    const approveTx = await token.approve(equityAddress.Equity, game.depositAmount);  
                    const approveReceipt = await approveTx.provider.waitForTransaction(approveTx.hash, 1);
                    
                    console.log("Transaction approve");
                    
                    const tx = await equity.deposit();
                    const receipt = await tx.provider.waitForTransaction(tx.hash, 1); 
                   
                   
                    console.log("Transaction sent");
                    
                    if (receipt.status === 1) {
                        console.log('Auction started successfully!');
                        await getGame();
                        const newBalance = await token.balanceOf(selectedAccount)
                        setBalance(Number(newBalance))
                    } else {
                        console.error('Transaction failed');
                    }
                            
                    
                }catch(error){
                console.error("Error send bet:", error);  
            
                }
                
            
            },


}))

export default useStore




    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

// const k = {
//         provider:null,
//         setProvider: (newProvider) => set({ provider: newProvider }),
//         token: null,
//         setToken: (newToken) => set({ token: newToken}),
//         auction: null, 
//         setAuction: (newAuction) => set({ auction: newAuction}),
//         nav:true, 
//         setNav: (newNav) => set({ nav: newNav}),
//         selectedAccount: null,
//         setSelectedAccount: (x) => set({ selectedAccount: x}),
//         balance: null,
//         setBalance: (x) => set({ balance: x}),
//         networkError:null,
//         setNetworkError: (x) => set({ nav: x}),

//         games: [],
//         setGames: (games) => set({ games }),
    
//         getGames: async () => {
            
//         const { auction, selectedAccount, setGames } = get()
    
//         if (!auction || !selectedAccount) return []
//         console.log(11111111);
    
//         const filterGameStarted = auction.filters.GameStarted()
//         const gameStartedEvents = await auction.queryFilter(filterGameStarted)
//         const games = []
    
//         for (const event of gameStartedEvents) {
//             const players = event.args.players.map(addr => addr.toLowerCase())
//             if (players.includes(selectedAccount)) {
//             const gameIdForUser = Number(event.args.gameId)
//             const _game = await auction.getGame(gameIdForUser)
    
//             const [playersRaw, bank, minAmount, lastTransactionTime, waitTime, gameId, winner] = _game
//             const players = Array.from(playersRaw).map(address => address.toLowerCase());

    
//             games.push({
//                 gameId: Number(gameId),
//                 bank: Number(bank),
//                 minAmount: Number(minAmount),
//                 lastTransactionTime: Number(lastTransactionTime),
//                 waitTime: Number(waitTime),
//                 players,
//                 winner:winner.toLowerCase()
//             })
//             }
//         }
    
//         setGames(games)
//         },

//         startGame: async (addresses, waitTime) =>{

//             const {token, getGames,setBalance, setNav, auction, selectedAccount} = get()
//             if (!token) {
//                 console.error('Token contract is not loaded');
//                 return;
//             }
//             const newAddresses = [...new Set(addresses)];          
//             if(newAddresses.length < 2){
//                 console.log('more then two addresses', addresses);
//                 return        
//             } 
//             try {
//                     const approveTx = await token.approve(auctionAddress.Auction, 1); // Пример с 18 знаками после запятой
//                     const approveReceipt = await approveTx.provider.waitForTransaction(approveTx.hash, 1);
//                     console.log('Token approved successfully:', approveReceipt.status);
//                     const tx = await auction.startGame(newAddresses, waitTime); // Отправляем транзакцию для старта игры
                
//                     console.log('Transaction sent, waiting for confirmation...');
        
//                     const receipt = await tx.provider.waitForTransaction(tx.hash, 1); // Ожидаем завершения транзакции    
//                     console.log("Transaction sent");
//                     if (receipt.status === 1) {
//                         console.log('Auction started successfully!');
//                         await getGames()
//                         const newBalance = await token.balanceOf(selectedAccount)
//                         setBalance(Number(newBalance))
//                         setNav(false)
        
//                     } else {
//                         console.error('Transaction failed');
//                     }
        
//                     console.log('auction was started');
                    
        
//                 } catch (error) {
//                     if (error.code === ERROR_CODE_TX_REJECTED_BY_USER) {
//                         console.log('Транзакция отклонена пользователем');
//                     } else {
//                         console.error('Error in startAuction:', error);
//                     }
//                 } 
//         },

//         win: async(gameId) => {

//             const {auction, getGames, token, setBalance, selectedAccount} = get()
//             try{

//                 const tx = await auction.endGame(gameId);
//                 const receipt = await tx.provider.waitForTransaction(tx.hash);
//                 if (receipt.status === 1) {
//                     console.log('game over');
//                     await getGames();
//                     const newBalance = await token.balanceOf(selectedAccount)
//                     setBalance(Number(newBalance))

//                 }else {
//                     console.error('Transaction failed');
//                 }
//             }catch(error){
//                 console.error('game over:', error)
//             }
//         },
//         sendBet: async(gameId, bet) =>{ 
//             const {token, auction, getGames} = get()

//             try{
//                 const approveTx = await token.approve(auctionAddress.Auction, bet);  
//                 const approveReceipt = await approveTx.provider.waitForTransaction(approveTx.hash, 1);
                
//                 console.log("Transaction approve");
                
//                 const tx = await auction.makeBet(gameId, bet);
//                 const receipt = await tx.provider.waitForTransaction(tx.hash, 1); 
               
               
//                 console.log("Transaction sent");
                
//                 if (receipt.status === 1) {
//                     console.log('Auction started successfully!');
//                     await getGames();
//                 } else {
//                     console.error('Transaction failed');
//                 }
                        
                
//             }catch(error){
//             console.error("Error send bet:", error);  
        
//             }
            
        
//         },


        
//     }




