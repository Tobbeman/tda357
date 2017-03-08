/* This is the driving engine of the program. It parses the command-line
 * arguments and calls the appropriate methods in the other classes.
 *
 * You should edit this file in three ways:
 * 1) Insert your database username and password in the proper places.
 * 2) Implement the generation of the world by reading the world file.
 * 3) Implement the three functions showPossibleMoves, showPlayerAssets
 *    and showScores.
 */
import java.math.BigDecimal;
import java.net.URL;
import java.sql.*; // JDBC stuff.
import java.util.*;
import java.io.*;  // Reading user input.
import java.util.concurrent.Executor;

public class Game
{
    public class Player
    {
        String playername;
        String personnummer;
        String country;
        private String startingArea;

        public Player (String name, String nr, String cntry, String startingArea) {
            this.playername = name;
            this.personnummer = nr;
            this.country = cntry;
            this.startingArea = startingArea;
        }
    }

    String USERNAME = "USERNAME";
    String PASSWORD = "PASSWORD";

    /* Print command optionssetup.
    * /!\ you don't need to change this function! */
    public void optionssetup() {
        System.out.println();
        System.out.println("Setup-Options:");
        System.out.println("		n[ew player] <player name> <personnummer> <country> <startingarea>");
        System.out.println("		d[one]");
        System.out.println();
    }

    /* Print command options.
    * /!\ you don't need to change this function! */
    public void options() {
        System.out.println("\nOptions:");
        System.out.println("    n[ext moves] [area name] [area country]");
        System.out.println("    l[ist properties] [player number] [player country]");
        System.out.println("    s[cores]");
        System.out.println("    r[efund] <area1 name> <area1 country> [area2 name] [area2 country]");
        System.out.println("    b[uy] [name] <area1 name> <area1 country> [area2 name] [area2 country]");
        System.out.println("    m[ove] <area1 name> <area1 country>");
        System.out.println("    p[layers]");
        System.out.println("    q[uit move]");
        System.out.println("    [...] is optional\n");
    }

    /* Given a town name, country and population, this function
      * should try to insert an area and a town (and possibly also a country)
      * for the given attributes.
      */
    void insertTown(Connection conn, String name, String country, String population) throws SQLException  {
        PreparedStatement statement;
       // sql = "INSERT INTO Countries VALUES ( '"+ country +"') ;";
        try{
            statement = conn.prepareStatement("INSERT INTO Countries (name) VALUES (?);");
            statement.setString(1, country);
            statement.executeUpdate();

        }catch (Exception e){
            //Country could already exist
        }

        statement = conn.prepareStatement("INSERT INTO Areas (country, name, population) VALUES (?, ?, cast(? as INT))");
        statement.setString(1, country);
        statement.setString(2, name);
        statement.setString(3, population);
        statement.executeUpdate();


        statement = conn.prepareStatement("INSERT INTO Towns (country, name) VALUES (?, ?);");
        statement.setString(1, country);
        statement.setString(2, name);
        statement.executeUpdate();


    }

    /* Given a city name, country and population, this function
      * should try to insert an area and a city (and possibly also a country)
      * for the given attributes.
      * The city visitbonus should be set to 0.
      */
    void insertCity(Connection conn, String name, String country, String population) throws SQLException {
        PreparedStatement statement;

        try{
            statement = conn.prepareStatement("INSERT INTO Countries (name) VALUES (?);");
            statement.setString(1, country);
            statement.executeUpdate();
        }catch (Exception e){
            //Country could already exist
        }

        statement = conn.prepareStatement("INSERT INTO Areas (country, name, population) VALUES (?, ?, cast(? as INT));");
        statement.setString(1, country);
        statement.setString(2, name);
        statement.setString(3, population);
        statement.executeUpdate();

        statement = conn.prepareStatement("INSERT INTO Cities (country, name, visitbonus) VALUES (?, ?, cast(? as INT));");
        statement.setString(1, country);
        statement.setString(2, name);
        statement.setString(3, "0");
        statement.executeUpdate();
    }

    /* Given two areas, this function
      * should try to insert a government owned road with tax 0
      * between these two areas.
      */
    void insertRoad(Connection conn, String area1, String country1, String area2, String country2) throws SQLException {

        PreparedStatement statement;

        statement = conn.prepareStatement("INSERT INTO ROADS (fromcountry, fromarea, tocountry, toarea, ownercountry, ownerpersonnumber, roadtax )" +
                "VALUES (?, ?, ?, ?, ?, ?, cast(? as INT));");
        statement.setString(1, country1);
        statement.setString(2, area1);
        statement.setString(3, country2);
        statement.setString(4, area2);
        statement.setString(5, "");
        statement.setString(6, "");
        statement.setString(7, "0");
        statement.executeUpdate();
    }

    /* Given a player, this function
     * should return the area name of the player's current location.
     */
    String getCurrentArea(Connection conn, Player person) throws SQLException {
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(
                "SELECT locationarea FROM Persons WHERE country='"+person.country+"' AND personnumber='"+ person.personnummer +"';" );
        rs.next();
        String result = rs.getString("locationarea");
        rs.close();
        return result;

    }

    /* Given a player, this function
     * should return the country name of the player's current location.
     */
    String getCurrentCountry(Connection conn, Player person) throws SQLException {
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(
                "SELECT locationcountry FROM Persons WHERE country='"+person.country+"' AND personnumber='"+ person.personnummer +"';" );
        rs.next();
        String result = rs.getString("locationcountry");
        rs.close();
        return result;
    }

    /* Given a player, this function
      * should try to insert a table entry in persons for this player
     * and return 1 in case of a success and 0 otherwise.
      * The location should be random and the budget should be 1000.
     */
    int createPlayer(Connection conn, Player person) throws SQLException {

        Statement stmt = conn.createStatement();
        String area = "";
        String country = "";
        String sql;
        PreparedStatement statement;
        ResultSet res = stmt.executeQuery(
                "SELECT name,country FROM Areas ORDER BY RANDOM() LIMIT 1;");


          /*
        Random rand = new Random();
        int index = rand.nextInt(count);

        ResultSet rs = stmt.executeQuery("SELECT * FROM Areas");
        */
          res.next();
        area = res.getString("name");
        country = res.getString("country");
        res.close();

        statement = conn.prepareStatement("INSERT INTO Persons (country, personnumber, name, locationcountry, locationarea, budget) VALUES" +
                "(?, ?, ?, ?, ?, cast(? as INT));");
        statement.setString(1, person.country);
        statement.setString(2, person.personnummer);
        statement.setString(3, person.playername);
        statement.setString(4, country);
        statement.setString(5, area);
        statement.setString(6, "1000");
        statement.executeUpdate();

        return 1;
    }

    /* Given a player and an area name and country name, this function
     * should show all directly-reachable destinations for the player from the
     * area from the arguments.
     * The output should include area names, country names and the associated road-taxes
      */
    void getNextMoves(Connection conn, Player person, String area, String country) throws SQLException {

        Statement stmt = conn.createStatement();

        ResultSet rsPerson = stmt.executeQuery("SELECT * FROM Persons WHERE country='"+person.country+"' AND personnumber='"+person.personnummer+"'");
        rsPerson.next();
        double budget = Double.parseDouble(rsPerson.getString("budget"));
        rsPerson.close();

        System.out.println("If the player " + person.playername + " is located in: " + area + " " + country + " the travel possibilities are:");
        ResultSet rsFrom = stmt.executeQuery(
                "SELECT * FROM Roads WHERE fromcountry='"+country+"' AND fromarea='"+area+"'; "
        );
        while(rsFrom.next()) {
            if(budget >=  Double.parseDouble(rsFrom.getString("roadtax")) ) {
                System.out.println(rsFrom.getString("tocountry") + " " + rsFrom.getString("toarea"));
            }

        }
        rsFrom.close();

        ResultSet rsTo = stmt.executeQuery(
                "SELECT * FROM Roads WHERE tocountry='"+country+"' AND toarea='"+area+"'; "
        );

        while(rsTo.next()) {
            if(budget >= Double.parseDouble(rsTo.getString("roadtax"))) {
                System.out.println(rsTo.getString("fromcountry") + " " + rsTo.getString("fromarea"));

            }

        }
        rsTo.close();

    }

    /* Given a player, this function
     * should show all directly-reachable destinations for the player from
     * the player's current location.
     * The output should include area names, country names and the associated road-taxes
     */
    void getNextMoves(Connection conn, Player person) throws SQLException {

        String area ="";
        String country="";
        double roadtax = 0;

        Statement stmt = conn.createStatement();

        ResultSet rs = stmt.executeQuery(
                "SELECT * FROM NextMoves WHERE personnumber = '" + person.personnummer +
                        "' AND country = '" + person.country + "';");

        while(rs.next()){
            area = rs.getString("validarea");
            country = rs.getString("validcountry");
            roadtax = Double.parseDouble(rs.getString("roadtax"));

            System.out.println("If player " + person.playername + "wants to travel to Area: " + area + " in Country: " + country + " it will cost him " + roadtax);
        }


    }

    /* Given a personnummer and a country, this function
     * should list all properties (roads and hotels) of the person
     * that is identified by the tuple of personnummer and country.
     */
    void listProperties(Connection conn, String personnummer, String country) {
        Statement stmt = null;
        try{
            stmt = conn.createStatement();
        }catch (Exception e){

        }

        String sql;

        ResultSet rs = null;
        try{
            rs = stmt.executeQuery("SELECT * FROM Roads WHERE '" + personnummer + "'=ownerpersonnumber AND '"+ country +"'=ownercountry;"  );
            System.out.println("Owned roads:");
            while(rs.next()){

                System.out.println("Between " + rs.getString(1)+ " "+ rs.getString(2) + " and " + rs.getString(3)+ " "+ rs.getString(4) + " with roadtax " + rs.getString(7));

            }
            System.out.println("");
            rs.close();
        }catch(Exception e){
            System.out.println("Exception in Roads");
            e.printStackTrace();
        }

        try{
            rs = stmt.executeQuery("SELECT * FROM Hotels WHERE '" + personnummer + "'=ownerpersonnumber AND '"+ country +"'=ownercountry;"  );
            System.out.println("Owned Hotels:");
            while(rs.next()){
                System.out.println("Hotelname: " + rs.getString(1) + " located in: " + rs.getString(2) + " " + rs.getString(3));

            }
            System.out.println("");
            rs.close();
        }catch(Exception e){
            System.out.println("Exception in Hotels");
            e.printStackTrace();
        }


    }

    /* Given a player, this function
     * should list all properties of the player.
     */
    void listProperties(Connection conn, Player person) throws SQLException {
        listProperties(conn, person.personnummer, person.country);
        /*
        Statement stmt = conn.createStatement();

        ResultSet rs = stmt.executeQuery("SELECT * FROM Persons WHERE " + person.personnummer + "=personnumber AND "+ person.country +"=country;"  );
        while(rs.next()) {
            System.out.print(rs.toString()); //THIS MIGHT NOT WORK
        }

        System.out.println("Owned entities:");
        listProperties(conn, person.personnummer, person.country);
*/
    }

    /* This function should print the budget, assets and refund values for all players.
     */
    void showScores(Connection conn) throws SQLException {
        Statement stmt = conn.createStatement();

        ResultSet rs = stmt.executeQuery("SELECT * FROM Assetsummary");
        while(rs.next()){
            if(rs.getString("country").compareTo("") == 0){
                continue;
            }
            System.out.println(rs.getString("country") + ", " + rs.getString("personnumber") + ", " + rs.getString("budget") + ", " + rs.getString("assets") + ", " + rs.getString("reclaimable") );
        }
        rs.close();
    }

    /* Given a player, a from area and a to area, this function
     * should try to sell the road between these areas owned by the player
     * and return 1 in case of a success and 0 otherwise.
     */
    int sellRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
        Statement stmt = conn.createStatement();
        int res = 1;
        try{
            stmt.executeQuery("DELETE FROM Roads WHERE "+person.personnummer+"=ownerpersonnumber AND "+person.country +"=ownercountry AND " +
                    area1+"=toarea AND " +
                    country1 +"=tocountry AND " +
                    area2 +"=fromarea AND " +
                    country2 + "=fromcountry ;" );

        }catch (Exception e1){
            res = 0;
        }


        try{
            stmt.executeQuery("DELETE FROM Roads WHERE "+person.personnummer+"=ownerpersonnumber AND "+person.country +"=ownercountry AND " +
                    area2+"=toarea AND " +
                    country2 +"=tocountry AND " +
                    area1 +"=fromarea AND " +
                    country1 + "=fromcountry ;" );
        }catch (Exception e2){
            System.out.println("Something went wrong inside sellRoad");
            System.out.println(e2.getLocalizedMessage() + "\n");
            res= 0;
        }


        return res;
    }

    /* Given a player and a city, this function
     * should try to sell the hotel in this city owned by the player
     * and return 1 in case of a success and 0 otherwise.
     */
    int sellHotel(Connection conn, Player person, String city, String country) throws SQLException {

        Statement stmt = conn.createStatement();
        int res = 1;
        try{
            stmt.executeUpdate("DELETE FROM Hotels WHERE '"+ person.country +"'=ownercountry AND '"+person.personnummer+"'=ownerpersonnumber AND '"+city+"'=locationname AND '"+country+"'=locationcountry;");

        } catch (Exception e){
            System.out.println("Something went wrong inside sellHotel");
            System.out.println(e.getLocalizedMessage() + "\n");
            e.printStackTrace();
            res = 0;
        }

        return res;
    }

    /* Given a player, a from area and a to area, this function
     * should try to buy a road between these areas owned by the player
     * and return 1 in case of a success and 0 otherwise.
     */
    int buyRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) throws SQLException {
        int res = 1;
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("INSERT INTO Roads (fromcountry, fromarea, tocountry, toarea, ownercountry, ownerpersonnumber, roadtax) VALUES" +
                    "(?, ?, ?, ?, ?, ?, cast(? as INT));");
            statement.setString(1, country1);
            statement.setString(2, area1);
            statement.setString(3, country2);
            statement.setString(4, area2);
            statement.setString(5, person.country);
            statement.setString(6, person.personnummer);
            statement.setString(7, "0");
            statement.executeUpdate();
        }   catch (Exception e){
            System.out.println("Something went wrong inside HotelbuyRoad");
            System.out.println(e.getLocalizedMessage() + "\n");
            res = 0;
        }

        return res;
    }

    /* Given a player and a city, this function
     * should try to buy a hotel in this city owned by the player
     * and return 1 in case of a success and 0 otherwise.
     */
    int buyHotel(Connection conn, Player person, String name, String city, String country) throws SQLException {
        int res = 1;
        try{
            PreparedStatement statement;
            statement = conn.prepareStatement("INSERT INTO Hotels (name, locationcountry, locationname, ownercountry, ownerpersonnumber) VALUES" +
                    "(?, ?, ?, ?, ?);");
            statement.setString(1, name);
            statement.setString(2, country);
            statement.setString(3, city);
            statement.setString(4, person.country);
            statement.setString(5, person.personnummer);

            statement.executeUpdate();
        }   catch (Exception e){
            System.out.println("Something went wrong inside buyHotel");
            System.out.println(e.getLocalizedMessage() + "\n");
            res = 0;
        }

        return res;

    }

    /* Given a player and a new location, this function
     * should try to update the players location
     * and return 1 in case of a success and 0 otherwise.
     */
    int changeLocation(Connection conn, Player person, String area, String country) throws SQLException {
        Statement stmt = conn.createStatement();
        int res = 1;
        try{
            stmt.executeUpdate("UPDATE Persons SET locationcountry='"+country+"', locationarea='"+ area+"' WHERE '"+person.personnummer+"'=personnumber AND '"+person.country+"'=country;");
        } catch (Exception e){
            System.out.println("Something went wrong inside changeLocation");
            System.out.println(e.getLocalizedMessage() + "\n");
            res = 0;
        }

        return res;
    }

    /* This function should add the visitbonus of 1000 to a random city
      */
    void setVisitingBonus(Connection conn) throws SQLException {
        Statement stmt = conn.createStatement();
        String area = "";
        String country = "";
        String sql;
        PreparedStatement statement;
        ResultSet res = stmt.executeQuery(
                "SELECT name,country FROM Cities ORDER BY RANDOM() LIMIT 1;");

        res.next();
        area = res.getString("name");
        country = res.getString("country");
        res.close();
        stmt.executeUpdate("UPDATE Cities SET visitbonus=1000 WHERE country='" + country + "' AND name='" + area + "'");
    }

    /* This function should print the winner of the game based on the currently highest budget.
      */
    void announceWinner(Connection conn) throws SQLException {
        Statement stmt = conn.createStatement();

        ResultSet res = stmt.executeQuery(
                "SELECT * FROM Persons ORDER BY budget DESC LIMIT 1");
        res.next();
        System.out.println("Winner is: " + res.getString("name"));
    }

    void play (String worldfile) throws IOException {

        // Read username and password from config.cfg
        try {
            BufferedReader nf = new BufferedReader(new FileReader("config.cfg"));
            String line;
            if ((line = nf.readLine()) != null) {
                USERNAME = line;
            }
            if ((line = nf.readLine()) != null) {
                PASSWORD = line;
            }
        } catch (Exception e) {
            System.out.println(e.getMessage());
        }

        if (USERNAME.equals("USERNAME") || PASSWORD.equals("PASSWORD")) {
            System.out.println("CONFIG FILE HAS WRONG FORMAT");
            return;
        }

        try {
            try {
                Class.forName("org.postgresql.Driver");
            } catch (Exception e) {
                System.out.println(e.getMessage());
            }
            String url = "jdbc:postgresql://ate.ita.chalmers.se/";
            Properties props = new Properties();
            props.setProperty("user",USERNAME);
            props.setProperty("password",PASSWORD);

            final Connection conn = DriverManager.getConnection(url, props);

			/* This block creates the government entry and the necessary
			 * country and area for that.
			 */
            try {
                PreparedStatement statement;
                statement = conn.prepareStatement("INSERT INTO Countries (name) VALUES (?)");
                statement.setString(1, "");
                statement.executeUpdate();
                statement = conn.prepareStatement("INSERT INTO Areas (country, name, population) VALUES (?, ?, cast(? as INT))");
                statement.setString(1, "");
                statement.setString(2, "");
                statement.setString(3, "1");
                statement.executeUpdate();
                statement = conn.prepareStatement("INSERT INTO Persons (country, personnumber, name, locationcountry, locationarea, budget) VALUES (?, ?, ?, ?, ?, cast(? as NUMERIC))");
                statement.setString(1, "");
                statement.setString(2, "");
                statement.setString(3, "Government");
                statement.setString(4, "");
                statement.setString(5, "");
                statement.setString(6, "0");
                statement.executeUpdate();
            } catch (SQLException e) {
                System.out.println(e.getMessage());
            }

            // Initialize the database from the worldfile
            try {
                BufferedReader br = new BufferedReader(new FileReader(worldfile));
                String line;
                while ((line = br.readLine()) != null) {
                    String[] cmd = line.split(" +");
                    if ("ROAD".equals(cmd[0]) && (cmd.length == 5)) {
                        insertRoad(conn, cmd[1], cmd[2], cmd[3], cmd[4]);
                    } else if ("TOWN".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a town entry in the database */
                        insertTown(conn, cmd[1], cmd[2], cmd[3]);
                    } else if ("CITY".equals(cmd[0]) && (cmd.length == 4)) {
						/* Create an area and a city entry in the database */
                        insertCity(conn, cmd[1], cmd[2], cmd[3]);
                    }
                }
            } catch (Exception e) {
                System.out.println(e.getMessage());
            }

            ArrayList<Player> players = new ArrayList<Player>();

            while(true) {
                optionssetup();
                String mode = readLine("? > ");
                String[] cmd = mode.split(" +");
                cmd[0] = cmd[0].toLowerCase();
                if(cmd[0].compareTo("test") == 0) {
                    Player test = new Player("test", "123456-9999", "Sweden", "asd");
                    createPlayer(conn, test) ;
                    //insertTown(conn, "testtown", "Sweden", "1234");
                    //insertCity(conn, "testcity", "Sweden", "1234") ;
                    //insertRoad(conn, String area1, String country1, String area2, String country2);
                    //System.out.println("Current area for: " + test.playername + "is: " + getCurrentArea(conn, test) );
                    //System.out.println("Current Country for: " + test.playername + " is: " + getCurrentCountry(conn, test) );
                    //getNextMoves(conn, test);
                    //getNextMoves(conn, test,"Gothenburg", "Sweden" );
                    //listProperties(conn, "", "") ;
                    //listProperties(conn, new Player("", "", "", "")) ;
                    //showScores(conn);
                    //buyHotel(conn, test, "testhotelletallan", "Gothenburg", "Sweden") ;
                    //sellHotel(conn, test, "Gothenburg", "Sweden");
                    //setVisitingBonus(conn);

                    //announceWinner(conn);


                    //int buyRoad(Connection conn, Player person, String area1, String country1, String area2, String country2) ;
                    //int changeLocation(Connection conn, Player person, String area, String country );

                }

                else if ("new player".startsWith(cmd[0]) && (cmd.length == 5)) {
                    Player nextplayer = new Player(cmd[1], cmd[2], cmd[3], cmd[4]);

                    if (createPlayer(conn, nextplayer) == 1) {
                        players.add(nextplayer);
                    }
                } else if ("done".startsWith(cmd[0]) && (cmd.length == 1)) {
                    break;
                } else {
                    System.out.println("\nInvalid option.");
                }
            }

            System.out.println("\nGL HF!");
            int roundcounter = 1;
            int maxrounds = 5;
            while(roundcounter <= maxrounds) {
                System.out.println("\nWe are starting the " + roundcounter + ". round!!!");
				/* for each player from the playerlist */
                for (int i = 0; i < players.size(); ++i) {
                    System.out.println("\nIt's your turn " + players.get(i).playername + "!");
                    System.out.println("You are currently located in " + getCurrentArea(conn, players.get(i)) + " (" + getCurrentCountry(conn, players.get(i)) + ")");
                    while (true) {
                        options();
                        String mode = readLine("? > ");
                        String[] cmd = mode.split(" +");
                        cmd[0] = cmd[0].toLowerCase();
                        if ("next moves".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* Show next moves from a location or current location. Turn continues. */
                            if (cmd.length == 1) {
                                String area = getCurrentArea(conn, players.get(i));
                                String country = getCurrentCountry(conn, players.get(i));
                                getNextMoves(conn, players.get(i));
                            } else {
                                getNextMoves(conn, players.get(i), cmd[1], cmd[2]);
                            }
                        } else if ("list properties".startsWith(cmd[0]) && (cmd.length == 1 || cmd.length == 3)) {
							/* List properties of a player. Can be a specified player
							   or the player himself. Turn continues. */
                            if (cmd.length == 1) {
                                listProperties(conn, players.get(i));
                            } else {
                                listProperties(conn, cmd[1], cmd[2]);
                            }
                        } else if ("scores".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
                            showScores(conn);
                        } else if ("players".startsWith(cmd[0]) && cmd.length == 1) {
							/* Show scores for all players. Turn continues. */
                            System.out.println("\nPlayers:");
                            for (int k = 0; k < players.size(); ++k) {
                                System.out.println("\t" + players.get(k).playername + ": " + players.get(k).personnummer + " (" + players.get(k).country + ") ");
                            }
                        } else if ("refund".startsWith(cmd[0]) && (cmd.length == 3 || cmd.length == 5)) {
                            if (cmd.length == 5) {
								/* Sell road from arguments. If no road was sold the turn
								   continues. Otherwise the turn ends. */
                                if (sellRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            } else {
								/* Sell hotel from arguments. If no hotel was sold the turn
								   continues. Otherwise the turn ends. */
                                if (sellHotel(conn, players.get(i), cmd[1], cmd[2]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            }
                        } else if ("buy".startsWith(cmd[0]) && (cmd.length == 4 || cmd.length == 5)) {
                            if (cmd.length == 5) {
								/* Buy road from arguments. If no road was bought the turn
								   continues. Otherwise the turn ends. */
                                if (buyRoad(conn, players.get(i), cmd[1], cmd[2], cmd[3], cmd[4]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            } else {
								/* Buy hotel from arguments. If no hotel was bought the turn
								   continues. Otherwise the turn ends. */
                                if (buyHotel(conn, players.get(i), cmd[1], cmd[2], cmd[3]) == 1) {
                                    break;
                                } else {
                                    System.out.println("\nTry something else.");
                                }
                            }
                        } else if ("move".startsWith(cmd[0]) && cmd.length == 3) {
							/* Change the location of the player to the area from the arguments.
							   If the move was legal the turn ends. Otherwise the turn continues. */
                            if (changeLocation(conn, players.get(i), cmd[1], cmd[2]) == 1) {
                                break;
                            } else {
                                System.out.println("\nTry something else.");
                            }
                        } else if ("quit".startsWith(cmd[0]) && cmd.length == 1) {
							/* End the move of the player without any action */
                            break;
                        } else {
                            System.out.println("\nYou chose an invalid option. Try again.");
                        }
                    }
                }
                setVisitingBonus(conn);
                ++roundcounter;
            }
            announceWinner(conn);
            System.out.println("\nGG!\n");

            conn.close();
        } catch (SQLException e) {
            System.err.println(e);
            System.exit(2);
        }
    }

    private String readLine(String s) throws IOException {
        System.out.print(s);
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(System.in));
        char c;
        StringBuilder stringBuilder = new StringBuilder();
        do {
            c = (char) bufferedReader.read();
            stringBuilder.append(c);
        } while(String.valueOf(c).matches(".")); // Without the DOTALL switch, the dot in a java regex matches all characters except newlines

        System.out.println("");
        stringBuilder.deleteCharAt(stringBuilder.length()-1);

        return stringBuilder.toString();
    }

    /* main: parses the input commands.
     * /!\ You don't need to change this function! */
    public static void main(String[] args) throws Exception
    {
        String worldfile = args[0];
        Game g = new Game();
        g.play(worldfile);
    }
}
