import { Dialog, DialogActions, DialogContent, DialogTitle, Button, createTheme, ThemeProvider,  TextField, Fab, InputAdornment} from '@mui/material';


export const theme = createTheme({
  palette: {
    primary: { main: '#faebd7' },
    secondary: { main: '#000000' },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          '&.Mui-disabled': {
            color: '#999999',          // цвет текста для disabled
            backgroundColor: '#222222', // цвет фона для disabled (если нужно)
          },
        },
      },
    },
  },
});
