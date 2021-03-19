import javax.swing.plaf.nimbus.State;
import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   // Can use if you wish: seat letters
   List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

   /**
    * Connects and sets the search path.
    *
    * Establishes a connection to be used for this session, assigning it to the
    * instance variable 'connection'. In addition, sets the search path to
    * 'air_travel, public'.
    *
    * @param url      the url for the database
    * @param username the username to connect to the database
    * @param password the password to connect to the database
    * @return true if connecting is successful, false otherwise
    */
   public boolean connectDB(String URL, String username, String password) {
      // Implement this method!
      try {
         System.out.println("Connecting to " + URL);

         this.connection = DriverManager.getConnection(URL, username, password);
         System.out.println("Connected");
         Statement statement = this.connection.createStatement();
         Boolean r = statement.execute("SET SEARCH_PATH TO air_travel, public;");

         return true;
      } catch (Exception e) {
         System.out.println(e);

      }
      return false;
   }

   /**
    * Closes the database connection.
    *
    * @return true if the closing was successful, false otherwise
    */
   public boolean disconnectDB() {
      try {
         System.out.println("Connection closed");
         this.connection.close();

         return true;
      } catch (Exception e) {
         System.out.println(e);
      }
      return false;
   }

   /* ======================= Airline-related methods ======================= */

   /**
    * Attempts to book a flight for a passenger in a particular seat class. Does so
    * by inserting a row into the Booking table.
    *
    * Read handout for information on how seats are booked. Returns false if seat
    * can't be booked, or if passenger or flight cannot be found.
    *
    *
    * @param passID    id of the passenger
    * @param flightID  id of the flight
    * @param seatClass the class of the seat (economy, business, or first)
    * @return true if the booking was successful, false otherwise.
    */
   public boolean bookSeat(int passID, int flightID, String seatClass) {
      try {
         if (!this.connection.isClosed()) {
            if (!(seatClass.equals("economy") || seatClass.equals("first") || seatClass.equals("business"))) {
               return false;
            }
            Statement statement = this.connection.createStatement();
            ResultSet set = statement.executeQuery("SELECT MAX(id) FROM BOOKING");
            set.next();
            int max = set.getInt(("max")) + 1;
            System.out.println("Max ID: " + max);
            set.next();
            ResultSet flight_q = statement
                  .executeQuery("SELECT * FROM BOOKING WHERE BOOKING.flight_id = " + flightID + ";");
            int current_capacity = 0;
            System.out.println("PASS ID's:");
            while (flight_q.next()) {
               System.out.println(flight_q.getInt("pass_id"));
               String seat_class = flight_q.getString("seat_class");
               if (seat_class.equals(seatClass)) {
                  current_capacity++;
               }
            }
            Statement statement1 = this.connection.createStatement();
            ResultSet flight_capacities = statement1
                  .executeQuery("select * from flight Join plane on flight.plane = plane.tail_number where flight.id ="
                        + flightID + ";");
            int seat_capacity = 0;
            int first_offset = 0;
            int business_offset = 0;

            while (flight_capacities.next()) {
               seat_capacity = flight_capacities.getInt("capacity_" + seatClass);
               first_offset = flight_capacities.getInt("capacity_first");
               business_offset = flight_capacities.getInt("capacity_business");
            }

            String insert = "INSERT INTO booking (id, pass_id, flight_id, datetime, price, seat_class, row, letter) VALUES (?,?,?,?,?,CAST(? as seat_class),?,?);";

            PreparedStatement preparedStatement = connection.prepareStatement(insert);

            Statement statement3 = this.connection.createStatement();
            ResultSet price_set = statement3
                  .executeQuery("SELECT * FROM PRICE WHERE PRICE.flight_id=" + flightID + ";");
            price_set.next();
            int price = price_set.getInt(seatClass);
            System.out.println(
                  "seat_capacity for " + seatClass + ": " + seat_capacity + " | current_capacity: " + current_capacity);
            if (current_capacity < seat_capacity) {
               int row_number = 0;
               if (seatClass.equals("first")) {
                  row_number = (int) Math.ceil(current_capacity / 5.99);
               } else if (seatClass.equals("business")) {
                  row_number = (int) Math.ceil(first_offset / 6.0) + (int) Math.ceil(current_capacity / 5.99);
               } else if (seatClass.equals("economy")) {
                  row_number = (int) Math.ceil(first_offset / 6.0) + (int) Math.ceil(business_offset / 6.0)
                        + (int) Math.ceil(current_capacity / 5.99);
               }
               if ((int) Math.ceil(current_capacity / 5.99) == 0) {
                  row_number += 1;
               }
               int seat_index = (current_capacity) % 6;

               preparedStatement.setInt(7, row_number);
               preparedStatement.setString(8, seatLetters.get(seat_index));
            } else if (seat_capacity <= current_capacity && current_capacity < seat_capacity + 10
                  && seatClass.equals("economy")) {
               preparedStatement.setNull(7, 0);
               preparedStatement.setNull(8, 0);
            } else if (current_capacity >= seat_capacity + 10 && seatClass.equals("economy")) {
               return false;
            } else if (current_capacity >= seat_capacity) {
               return false;
            }
            System.out.println("HERE4");
            preparedStatement.setInt(1, max);
            preparedStatement.setInt(2, passID);
            preparedStatement.setInt(3, flightID);
            preparedStatement.setTimestamp(4, getCurrentTimeStamp());
            preparedStatement.setInt(5, price);
            preparedStatement.setString(6, seatClass);
            preparedStatement.execute();
            System.out.println(preparedStatement);
            return true;
         }
      } catch (Exception e) {
         System.out.println("BookSeat: " + e);
      }
      return false;
   }

   /**
    * Attempts to upgrade overbooked economy passengers to business class or first
    * class (in that order until each seat class is filled). Does so by altering
    * the database records for the bookings such that the seat and seat_class are
    * updated if an upgrade can be processed.
    *
    * Upgrades should happen in order of earliest booking timestamp first.
    *
    * If economy passengers left over without a seat (i.e. more than 10 overbooked
    * passengers or not enough higher class seats), remove their bookings from the
    * database.
    *
    * @param flightID The flight to upgrade passengers in.
    * @return the number of passengers upgraded, or -1 if an error occured.
    */
   public int upgrade(int flightID) {
      try {
         if (!this.connection.isClosed()) {
            Statement statement = this.connection.createStatement();
            System.out.println("HERE");
            ResultSet flight_q = statement
                  .executeQuery("SELECT * FROM BOOKING WHERE BOOKING.flight_id = " + flightID + ";");
            int first_cap = 0;
            int business_cap = 0;
            while (flight_q.next()) {
               System.out.println(flight_q.getInt("pass_id"));
               String seat_class = flight_q.getString("seat_class");
               if (seat_class.equals("first")) {
                  first_cap++;
               } else if (seat_class.equals("business")) {
                  business_cap++;
               }

            }
            Statement statement1 = this.connection.createStatement();

            ResultSet flight_capacities = statement1
                  .executeQuery("select * from flight Join plane on flight.plane = plane.tail_number where flight.id ="
                        + flightID + ";");
            int first_max = 0;
            int business_max = 0;
            while (flight_capacities.next()) {
               first_max = flight_capacities.getInt("capacity_first");
               business_max = flight_capacities.getInt("capacity_business");
            }
            int num_ugpraded = 0;
            System.out.println("FEWFE");
            Statement statement3 = this.connection.createStatement();
            ResultSet set = statement3.executeQuery(
                  "SELECT * FROM BOOKING WHERE flight_id=" + flightID + " AND seat_class='economy' AND row is NULL;");

            while (set.next()) {

               int pass_id = set.getInt("pass_id");
               int booking_id = set.getInt("id");
               System.out.println("BOOKING ID: " + set.getInt("id") + ", PASS ID: " + set.getInt("pass_id"));
               Statement statement2 = this.connection.createStatement();
               System.out.println("FIRST CAP: " + first_cap + " Business CAP: " + business_cap);

               if (business_cap < business_max) {
                  Statement update = this.connection.createStatement();
                  int row_number = (int) Math.ceil(first_max / 6.0) + (int) Math.ceil(business_cap / 5.99);
                  if ((int) Math.ceil(business_cap / 5.99) == 0) {
                     row_number += 1;
                  }
                  int seat_index = (business_cap) % 6;

                  String letter = seatLetters.get(seat_index);
                  System.out.println("UPDATE BOOKING SET seat_class=CAST('business' as seat_class), row= " + row_number
                        + ",letter=" + letter + " WHERE BOOKING.id = " + booking_id + ";");

                  update.executeUpdate("UPDATE BOOKING SET seat_class=CAST('business' as seat_class), row= "
                        + row_number + ",letter='" + letter + "' WHERE BOOKING.id = " + booking_id + ";");
                  num_ugpraded++;
                  business_cap++;
               }

               else if (first_cap < first_max) {
                  Statement update = this.connection.createStatement();
                  int row_number = (int) Math.ceil(first_cap / 5.99);
                  if ((int) Math.ceil(first_cap / 5.99) == 0) {
                     row_number += 1;
                  }
                  int seat_index = (first_cap) % 6;

                  String letter = seatLetters.get(seat_index);
                  System.out.println("UPDATE BOOKING SET seat_class=CAST('first' as seat_class), row= " + row_number
                        + ",letter=" + letter + " WHERE BOOKING.id = " + booking_id + ";");
                  update.executeUpdate("UPDATE BOOKING SET seat_class=CAST('first' as seat_class), row= " + row_number
                        + ",letter='" + letter + "' WHERE BOOKING.id = " + booking_id + ";");

                  num_ugpraded++;
                  first_cap++;
               }

               if (first_cap >= first_max && business_cap >= business_max) {
                  System.out.println("first_cap: " + first_cap + ", " + "business_cap: " + business_cap);
                  System.out.println("first_max: " + first_max + ", " + "business_max: " + business_max);
                  Statement delete_nulls = this.connection.createStatement();
                  System.out.println("HERE3");
                  delete_nulls.execute("DELETE FROM Booking WHERE seat_class='economy' AND row is NULL");
                  return num_ugpraded;
               }

            }
            Statement delete_nulls = this.connection.createStatement();

            delete_nulls.execute("DELETE FROM Booking WHERE seat_class='economy' AND row is NULL");

            return num_ugpraded;

         }
      } catch (Exception e) {
         System.out.println("UPGRADE" + e);
         return -1;
      }
      return -1;

   }

   /* ----------------------- Helper functions below ------------------------- */

   // A helpful function for adding a timestamp to new bookings.
   // Example of setting a timestamp in a PreparedStatement:
   // ps.setTimestamp(1, getCurrentTimeStamp());

   /**
    * Returns a SQL Timestamp object of the current time.
    *
    * @return Timestamp of current time.
    */
   private java.sql.Timestamp getCurrentTimeStamp() {
      java.util.Date now = new java.util.Date();
      return new java.sql.Timestamp(now.getTime());
   }

   // Add more helper functions below if desired.

   /* ----------------------- Main method below ------------------------- */

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      try {
         Assignment2 ass = new Assignment2();
         ass.connectDB("jdbc:postgresql://localhost:5432/A2", "postres", "<password>");
         for (int i = 0; i < 3; i++) {
            ass.bookSeat(6, 5, "economy");
         }
         for (int i = 0; i < 7; i++) {
            ass.bookSeat(1, 5, "business");
         }
         ass.bookSeat(3, 5, "first");
         System.out.println("NUM UPGRADED: " + ass.upgrade(10));
         ass.disconnectDB();
      } catch (Exception e) {
         System.out.println(e);
      }
   }

}
