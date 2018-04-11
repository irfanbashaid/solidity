pragma solidity ^0.4.0;
import "./High_low_token.sol";
contract High_low
{
    //address this_address;
    High_low_token token;
    
    function High_low(High_low_token _token) public payable
    {
        admin=msg.sender;
        token = _token;
       // this_address=address(this);
    }
    //for High_low_token 
    
    
    
    function buy_token() public payable returns(bool)
    {
        High_low_token(token).transferFrom(token,msg.sender, msg.value/0.1 ether);
        return true;
    }
    
    function add_stake_token(uint256 token_to_stake) public payable returns(bool)
    {
        require(High_low_token(token).balanceOf(msg.sender)>=token_to_stake);
        High_low_token(token).transferFrom(msg.sender,address(this),token_to_stake);
        broker_map[msg.sender].stake_tokens+=token_to_stake;
        return true;
    }
    
    
    
    address public admin;
    uint256 public game_id;
    
    
    function() public payable {}
    
    address[] public broker_addresses;
    
    event Transfer_amount(address _sender,address _receiver,uint256 _transfer_amount);
    
    struct  broker
    {
        uint256 stake_amount;
        uint256 stake_tokens;
    }
    mapping(address=>broker) public broker_map;
    
    struct better
    {
        uint256 bet_amount; 
        address better_address;
        bool option;
        uint256 betted_tokens;
        address bet_creator;
    }
    mapping(uint256=>mapping(uint256=>better)) public game_id_map_trader;//key: bet_id  value:betting     "for UI get index of struct from struct_index_of_bet_of_trader" 
    
    mapping(address=>mapping(uint256=>uint256)) public struct_index_of_bet_of_trader;//trader ,game_id value:index
    
    mapping(uint256=>address) public game_id_map_broker;//key:game_id game_id_map_broker[]
    
    mapping(uint256=>uint256) public total_bet_amount; //key: gameid  value:total bet amount of that particular bet
    
    mapping(uint256=>uint256) public total_bet_tokens; //key: gameid  value:total bet amount of that particular bet
    
    mapping(uint256=>uint256) public gamers_map;//key:game_id value:gamers how many gamers playing this game
    
    struct game_set
    {
        uint256 game_ids;
        string stock_name;
        uint256 strike_price;
        uint256 expiry_time;
    }
    mapping(address=>mapping(uint256=>game_set)) public game_set_map;//key1:broker_address key2:game_number     "for UI get index of struct for broker get from struct_index_of_bet_of_broker" 
    
    mapping(address=>mapping(uint256=>uint256)) public struct_index_of_bet_of_broker;//broker ,game_id value:index     
    
    struct result_status
    {
        bool is_result_published;
        uint256 final_option;
    }
    mapping(uint256=>result_status) public result_map;//to check is_result_published 
    
    mapping(address=>uint256[]) public trader_betted_games; //key:trader address 
    
    mapping(address=>uint256) public game_number;//key:broker value:game_number
    
    mapping(address=>bool) public valid_trader;//to accept as valid trader
    
    mapping(address=>uint256) public maximum_expiry_time_of_bet;

    function view_stake() constant public returns(uint256)
    {
        return broker_map[msg.sender].stake_amount;
    }
    
    function view_stake_token() constant public returns(uint256)
    {
        return broker_map[msg.sender].stake_tokens;
    }
    
    function check_broker() public constant returns(bool) // is_broker
    {
        return broker_map[msg.sender].stake_amount!=0;
    }
    
    function add_broker() public payable returns (bool) // is_added
    {
         broker_map[msg.sender].stake_amount=msg.value;
         broker_addresses.push(msg.sender);
         Transfer_amount(msg.sender,admin,msg.value);
         return true;
    }
    
    function length_of_broker_addresses() public constant returns(uint256)
    {
        return broker_addresses.length;
    }
    
    function get_broker_address(uint256 _index) public constant returns(address)
    {
        return broker_addresses[_index];
    }
    
    function check_admin() public constant returns(bool)
    {
        return admin==msg.sender;    
    }
    
    function length_of_trader_betted_games() public constant returns(uint256)
    {
        return trader_betted_games[msg.sender].length;
    }
    
    function broker_set_game(string _stock_name,uint256 _strike_price,uint256 _expiry_time) public payable returns(bool,uint256) // newbet, new_game_id
    {
        require(_expiry_time>now);
        game_set_map[msg.sender][game_number[msg.sender]].stock_name=_stock_name;
        game_set_map[msg.sender][game_number[msg.sender]].strike_price=_strike_price;
        game_set_map[msg.sender][game_number[msg.sender]].expiry_time=_expiry_time;
        game_set_map[msg.sender][game_number[msg.sender]].game_ids=game_id;
        result_map[game_id].is_result_published=false;
        struct_index_of_bet_of_broker[msg.sender][game_id]=game_number[msg.sender];//address=>mapping(uint256=>uint256)) public struct_index_of_bet_of_broker;//broker ,game_id value:index
        if(maximum_expiry_time_of_bet[msg.sender]<_expiry_time)
        maximum_expiry_time_of_bet[msg.sender]=_expiry_time;
        game_id_map_broker[game_id]=msg.sender;
        game_id++;
        game_number[msg.sender]++;
        return (true,(game_id-1));
    }
    
    function add_broker_stake() public payable returns(bool,uint256) //amount_added , stake_amount_is
    {
        require(msg.value>0);
        broker_map[msg.sender].stake_amount+=msg.value;
        Transfer_amount(msg.sender,admin,msg.value);
        return (true,broker_map[msg.sender].stake_amount);
    }
    
    function check_trader() public constant returns(bool) //is_already_a_trader
    {
        return valid_trader[msg.sender]==true;
    }
        
    function betting(uint256 _game_id,uint256 _choice,uint256 _bet_tokens) public payable returns(bool) // is_bet_success 
    {
        require(game_set_map[game_id_map_broker[_game_id]][struct_index_of_bet_of_broker[game_id_map_broker[_game_id]][_game_id]].expiry_time - 1 minutes>now);
        require(_bet_tokens>0 || msg.value>0);
        require((broker_map[game_id_map_broker[_game_id]].stake_amount+
        broker_map[game_id_map_broker[_game_id]].stake_tokens*100000000000000000)
        >
        ((90*msg.value)/100+(90*_bet_tokens*100000000000000000)/100));
        if(_bet_tokens>0)
        {
            require(High_low_token(token).balanceOf(msg.sender)>=_bet_tokens);
        }
        require(struct_index_of_bet_of_trader[msg.sender][_game_id] == 0);
        require(_choice==1||_choice==0);
        bool _option;
        if(_choice==1)
        {
            _option=true;
        }
        else if(_choice==0)
        {
            _option=false;
        }
        gamers_map[_game_id]++;
        if(msg.value!=0)//for ether bet
        {
            if(broker_map[game_id_map_broker[_game_id]].stake_amount-(90*msg.value)/100>0)
            {
                broker_map[game_id_map_broker[_game_id]].stake_amount-=(90*msg.value)/100;
            }
            else
            {
                uint256 reduced;
                reduced=broker_map[game_id_map_broker[_game_id]].stake_amount;
                broker_map[game_id_map_broker[_game_id]].stake_amount=0;
                broker_map[game_id_map_broker[_game_id]].stake_tokens-=((90*msg.value)/100 - reduced)/0.1 ether;
            }
                
            game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount=msg.value;
            total_bet_amount[_game_id]+=msg.value;
            Transfer_amount(msg.sender,this,msg.value);
        }
        else //for token bet
        {
            High_low_token(token).transferFrom(msg.sender,this,_bet_tokens);
            if((broker_map[game_id_map_broker[_game_id]].stake_amount-(90*_bet_tokens*100000000000000000)/100)>0)
            {
                broker_map[game_id_map_broker[_game_id]].stake_amount-=(90*_bet_tokens*100000000000000000)/100;
            }
            else
            {
                uint256 reduced_amount;
                reduced_amount=broker_map[game_id_map_broker[_game_id]].stake_amount;
                broker_map[game_id_map_broker[_game_id]].stake_amount=0;
                broker_map[game_id_map_broker[_game_id]].stake_tokens-=_bet_tokens-(reduced_amount/0.1 ether);
            }
            game_id_map_trader[_game_id][gamers_map[_game_id]].betted_tokens=_bet_tokens;
            total_bet_tokens[_game_id]+=_bet_tokens;
            Transfer_amount(msg.sender,this,_bet_tokens);
        }
        if(valid_trader[msg.sender]==false)
        valid_trader[msg.sender]=true;//new trader
        game_id_map_trader[_game_id][gamers_map[_game_id]].bet_creator=game_id_map_broker[_game_id];
        game_id_map_trader[_game_id][gamers_map[_game_id]].better_address=msg.sender;
        game_id_map_trader[_game_id][gamers_map[_game_id]].option=_option;
        struct_index_of_bet_of_trader[msg.sender][_game_id]=gamers_map[_game_id];
        trader_betted_games[msg.sender].push(_game_id);
        return true;
    }
    
    function admin_setting_result_and_distribute_money(uint256 _game_id,uint256 result_options) public payable returns(bool)// is_result_setted_and_prize_distributed 
    {
        require(admin==msg.sender);
        require(game_set_map[game_id_map_broker[_game_id]][struct_index_of_bet_of_broker[game_id_map_broker[_game_id]][_game_id]].expiry_time<now);
        require(result_map[_game_id].is_result_published==false);
        require(result_options<3 && result_options>=0);
        result_map[_game_id].is_result_published=true;
        result_map[_game_id].final_option=result_options;
        bool result_option;
        uint256 index=gamers_map[_game_id];
        if(result_options==2)
        {
            //draw
            while(gamers_map[_game_id]>0)
            {
                if(game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount!=0)
                {
                    broker_map[game_id_map_broker[_game_id]].stake_amount+=(90*game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount)/100;
                    game_id_map_trader[_game_id][gamers_map[_game_id]].better_address.transfer(game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount);
                    Transfer_amount(admin,game_id_map_trader[_game_id][gamers_map[_game_id]].better_address,game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount);//trader transfer
                }
                else
                {
                    
                }
                gamers_map[_game_id]--;
            }
            gamers_map[_game_id]=index;
            return true;
        }
        else if(result_options==1)
        {
            //set high as result_option
            result_option=true;
        }
        else if(result_options==0)
        {
            //set low as result_option
            result_option=false;
        }
        while(gamers_map[_game_id]>0)
        {
            if(game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount!=0)
            {
                if(result_option==game_id_map_trader[_game_id][gamers_map[_game_id]].option)
                {
                    game_id_map_trader[_game_id][gamers_map[_game_id]].better_address.transfer((189*game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount)/100);
                    Transfer_amount(admin,game_id_map_trader[_game_id][gamers_map[_game_id]].better_address,(189*game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount)/100);//transfer amount to trader
                }
                else
                {
                    broker_map[game_id_map_broker[_game_id]].stake_amount+=(199*game_id_map_trader[_game_id][gamers_map[_game_id]].bet_amount)/100;
                }
            }
            gamers_map[_game_id]--;
        }
        gamers_map[_game_id]=index;
        return true;
    }
    
    function trader_increase_bet_amount(uint256 _game_id) public payable returns(bool)// is_increase_success
    {
        require(game_set_map[game_id_map_broker[_game_id]][struct_index_of_bet_of_broker[game_id_map_broker[_game_id]][_game_id]].expiry_time - 1 minutes>now);
        require(msg.value>0 && broker_map[game_id_map_broker[_game_id]].stake_amount>=(90*msg.value)/100);
        game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount+=msg.value;
        broker_map[game_id_map_broker[_game_id]].stake_amount-=(90*msg.value)/100;
        total_bet_amount[_game_id]+=msg.value;
        Transfer_amount(admin,msg.sender,msg.value);
        return true;
    }
    
    function trader_decrease_bet_amount(uint256 _game_id,uint256 input_amount) public payable returns(bool)// is_increase_success
    {
        require(500000000000000000<=game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount);
        require(input_amount>0);
        require(game_set_map[game_id_map_broker[_game_id]][struct_index_of_bet_of_broker[game_id_map_broker[_game_id]][_game_id]].expiry_time - 1 minutes>now);
        game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount-=input_amount;
        broker_map[game_id_map_broker[_game_id]].stake_amount+=(90*input_amount)/100;
        total_bet_amount[_game_id]-=input_amount;
        msg.sender.transfer(input_amount);
        Transfer_amount(msg.sender,admin,input_amount);
        return true;
    }
    
    function trader_cancel_bet_and_widthdraw(uint256 _game_id) public payable returns(bool)// is_withdraw_success
    {
        require(game_set_map[game_id_map_broker[_game_id]][struct_index_of_bet_of_broker[game_id_map_broker[_game_id]][_game_id]].expiry_time - 1 minutes>now);
        game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].better_address.transfer((95*game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount)/100);
        broker_map[game_id_map_broker[_game_id]].stake_amount+=(95*game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount)/100;
        total_bet_amount[_game_id]-=game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount;
        game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount=0;
        gamers_map[_game_id]--;
        Transfer_amount(admin,msg.sender,(95*game_id_map_trader[_game_id][struct_index_of_bet_of_trader[msg.sender][_game_id]].bet_amount)/100);
        return true;
    }
    
    function broker_de_registration() public payable returns(bool) // is_de_registered
    {
        require(maximum_expiry_time_of_bet[msg.sender] + 1 minutes < now);
        msg.sender.transfer(broker_map[msg.sender].stake_amount);
        broker_map[msg.sender].stake_amount=0;
        Transfer_amount(admin,msg.sender,broker_map[msg.sender].stake_amount);
        return true;
    }
    
    function broker_withdraw_amount_from_stake(uint256 input_amount_to_withdraw) public payable returns(bool) // is_de_registered
    {
        require(input_amount_to_withdraw>0 && input_amount_to_withdraw < broker_map[msg.sender].stake_amount-1);
        broker_map[msg.sender].stake_amount-=input_amount_to_withdraw;
        msg.sender.transfer(input_amount_to_withdraw);
        Transfer_amount(admin,msg.sender,input_amount_to_withdraw);
        return true;
    }
    
}
