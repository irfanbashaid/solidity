pragma solidity ^0.4.0;
library SafeMath 
{
    
    function add(uint a, uint b) internal pure returns (uint) 
    {
        uint c;
        c = a + b;
        require(c >= a);
        return c;
    }
    
    function sub(uint a, uint b) internal pure returns (uint) 
    {
        require(b <= a);
        uint c;
        c = a - b;
        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint) 
    {
        uint c;
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint a, uint b) internal pure returns (uint) 
    {
        require(b > 0);
        uint c;
        c = a / b;
        return c;
    }
    
}

contract High_low_token
{
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;
    address public token_address;
    
    function High_low_token() public payable
    {
        symbol = "HLT";
        name = "High Low Token";
        decimals = 0;
        _totalSupply = 1000000 * 10**uint(decimals);
        token_address=address(this);
        balances[token_address]= _totalSupply;
        owner=msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function() public payable { }

    function totalSupply() public constant returns (uint256) 
    {
        return _totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256) 
    {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public payable returns (bool) 
    {
        require(balances[msg.sender] >= _value &&  _value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);//calling library
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public payable returns (bool) 
    {
        require(balances[_from] >= _value && _value > 0);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public payable returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) 
    {
        return allowed[_owner][_spender];
    }

}
