pragma solidity ^0.4.0;
contract ERC20_Bank_wallet
{
    event Approval(address owner, address spender,uint256 amount);
    event Transfer(address from, address to, uint256 amount);
    mapping(address=>uint)acc;
    mapping(address=>mapping(address=>uint))spender_map;
    function totalSupply(uint256 amount) returns (uint256)
    {
        acc[msg.sender]=amount;
        return acc[msg.sender];
    }
    function balanceOf(address acc_holder) public constant returns (uint256) 
    {
        return acc[acc_holder];
    }
    function transfer(address transfer_to, uint256 amount) returns (bool) 
    {
        if(acc[msg.sender]>amount)
        {
            acc[transfer_to]+=amount;
            acc[msg.sender]-=amount;
            Transfer(msg.sender,transfer_to,amount);
            return true;
        }
        else
            return false;
    }
    function approve(address spender, uint256 amount) returns (bool)
    {
        if(acc[msg.sender]>amount)
        {
            spender_map[msg.sender][spender]=amount;
            Approval(msg.sender,spender,amount);
            return true;
        }
        else
            return false;
    }
    function transferFrom(address spender, address transfer_to, uint256 amount) returns (bool) 
    {
        if(spender_map[msg.sender][spender]>amount)
        {
            acc[transfer_to]+=amount;
            spender_map[msg.sender][spender]-=amount;
            acc[msg.sender]-=amount;
            Transfer(spender,transfer_to,amount);
            return true;
        }
        else
            return false;
    }
    function allowance(address spender) public constant returns (uint256) 
    {
        return spender_map[msg.sender][spender];
    }
}
