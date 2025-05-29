import * as React from 'react';
import PropTypes from 'prop-types';
import Button from '@mui/material/Button';
import DialogTitle from '@mui/material/DialogTitle';
import Dialog from '@mui/material/Dialog';
import Typography from '@mui/material/Typography';

import CloseIcon from '@mui/icons-material/Close';
import IconButton from '@mui/material/IconButton';

const emails = ['username@gmail.com', 'user02@gmail.com'];

function SimpleDialog(props) {
  const { onClose, selectedValue, open, errors } = props;

  const handleClose = () => {
    onClose(selectedValue);
  };

  const handleListItemClick = (value) => {
    onClose(value);
  };
    return (
  
      <Dialog onClose={handleClose} open={open} 
      sx={{
        '& .MuiDialog-paper': {
          background:"#faebd7",
          padding: '0 40px 30px 40px',
          borderRadius: '8px',
          boxShadow: '0px 4px 20px rgba(0, 0, 0, 0.2)', // Тень для диалогового окна
        },
        }}>
        <DialogTitle 
        sx={{
          textAlign:'center',
          fontWeight: 900  
        }}
        
        >Error</DialogTitle>
        <Typography>
          {errors.smallBalance && <>Balance too low. <br/></>}
          {errors.connect && <>Connect with metamask. <br/></>}
          {errors.depositAmount && <>amount must be higher than deposit.<br/></>}
          {errors.depositZero && <>Deposit must be higher then 0. <br/></>}
          {errors.amountZero && <>Amount must be higher then 0. <br/></>}
          {errors.interval && <>It's old interval, please wait. <br/></>}

        </Typography>
        <IconButton onClick={() => handleClose()} color="secondary" 
        sx={{ marginLeft: 0, position:'absolute', top:0,right:0 }}>
              <CloseIcon />
        </IconButton>
      </Dialog>
    );
  

}

SimpleDialog.propTypes = {
  onClose: PropTypes.func.isRequired,
  open: PropTypes.bool.isRequired,
  selectedValue: PropTypes.string.isRequired,
};









export default function ConnectAlert({errors, knopka, text}) {
  const [open, setOpen] = React.useState(false);
  const [selectedValue, setSelectedValue] = React.useState(emails[1]);

  const handleClickOpen = () => {
    setOpen(true);
  };

  const handleClose = (value) => {
    setOpen(false);
    setSelectedValue(value);
  };

  
  return (
 
    <div>
      <Button variant={knopka} color="primary" onClick={handleClickOpen} sx={{ margin: '10px' }}>
      {text}
      </Button>
      <SimpleDialog
        selectedValue={selectedValue}
        open={open}
        onClose={handleClose}
        errors = {errors}
      />
    </div>

     

  );



  

}

