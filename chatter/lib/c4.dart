import 'dart:io';
import 'dart:typed_data';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ConnectionState
{
  Socket? theServer = null;
  bool listened = false;

  ConnectionState( this.theServer, this.listened );
}

class ConnectionCubit extends Cubit<ConnectionState>
{
  ConnectionCubit() : super( ConnectionState( null, false) )
  {
    if ( state.theServer==null ) { connect(); }
  }

  update( Socket s ) { emit( ConnectionState(s,state.listened) ); }

  updateListen() { emit( ConnectionState(state.theServer, true ) ); }

  Future<void> connect() async
  {
    await Future.delayed( const Duration(seconds:2) );
    final socket = await Socket.connect('localhost', 9203);
    print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
    update(socket);
  }
}

class SaidState
{
   String said;

   SaidState( this.said );
}

class SaidCubit extends Cubit<SaidState>
{
  SaidCubit() : super( SaidState("and so it begins ....\n" ) );

  void update( String s )
  {
    emit( SaidState("${state.said}$s\n") );
  }
}

void main()
{
  runApp( Client() );
}

class Client extends StatelessWidget
{
  @override
  Widget build( BuildContext context )
  {
    return MaterialApp
    (
      title: "client",
      home: BlocProvider<ConnectionCubit>
      (
        create: (context) => ConnectionCubit(),
        child: BlocBuilder<ConnectionCubit,ConnectionState>
        (
          builder: (context, state) => BlocProvider<SaidCubit>
          (
            create: (context) => SaidCubit(),
            child: BlocBuilder<SaidCubit,SaidState>
            (
              builder: (context,state) => Client2(),
            ),
          ),
        ),
      ),
    );
  }
}

class Client2 extends StatelessWidget
{
  final TextEditingController tec = TextEditingController();

  @override
  Widget build( BuildContext context )
  {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if ( cs.theServer != null && !cs.listened )
    {
      listen(context);
    }

    return Scaffold
    (
      appBar: AppBar( title: Text("client") ),
      body: Column
      (
        children:
        [
          SizedBox
          (
            child: TextField(controller: tec)
          ),
          cs.theServer!=null
          ? ElevatedButton
            (
              onPressed: ()
              {
                String msg = "Client: ${tec.text}";
                cs.theServer!.write(msg);
                sc.update(msg);
                tec.clear();
              },
              child: Text("send to server"),
            )
          : Text("not ready"),
          cs.theServer!=null
          ? Expanded(
              child: SingleChildScrollView(
                child: Text(sc.state.said),
              ),
            )
          : Text("waiting for call to go through ..."),
        ],
      ),
    );
  }

  void listen( BuildContext bc )
  {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theServer!.listen
    (
      (Uint8List data) async
      {
        final message = String.fromCharCodes(data);
        sc.update(message);
      },
      onError: (error)
      {
        print(error);
        cs.theServer!.close();
      },
    );

    cc.updateListen();
  }
}