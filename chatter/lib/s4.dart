import 'dart:io';
import 'dart:typed_data';

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ConnectionState
{
  bool listening = false;
  Socket? theClient = null;
  bool listened = false;

  ConnectionState( this.listening, this.theClient, this.listened );
}

class ConnectionCubit extends Cubit<ConnectionState>
{
  ConnectionCubit() : super( ConnectionState(false, null, false) )
  {
    if (!state.listening) { connect(); }
  }

  update( bool b, Socket s ) { emit( ConnectionState(b,s, state.listened) ); }

  updateListen() { emit( ConnectionState(true,state.theClient,true) ); }

  Future<void> connect() async
  {
    await Future.delayed( const Duration(seconds:2) );
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9203);

    server.listen
    (
      (client)
      {
        emit( ConnectionState(true,client, state.listened) );
      }
    );

    emit( ConnectionState(true,null, false) );
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
  runApp( Server() );
}

class Server extends StatelessWidget
{
  @override
  Widget build( BuildContext context )
  {
    return MaterialApp
    (
      title: "server",
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
              builder: (context,state) => Server2(),
            ),
          ),
        ),
      ),
    );
  }
}

class Server2 extends StatelessWidget
{
  final TextEditingController tec = TextEditingController();

  @override
  Widget build( BuildContext context )
  {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(context);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(context);

    if ( cs.theClient != null && !cs.listened )
    {
      listen(context);
    }

    return Scaffold
    (
      appBar: AppBar( title: Text("server") ),
      body: Column
      (
        children:
        [
          SizedBox
          (
            child: TextField(controller: tec)
          ),
          cs.theClient!=null
          ? ElevatedButton
            (
              onPressed: ()
              {
                String msg = "Server: ${tec.text}";
                cs.theClient!.write(msg);
                sc.update(msg);
                tec.clear();
              },
              child: Text("send to client"),
            )
          : Text("not ready"),
          cs.listening
          ? cs.theClient!=null
            ? Expanded(
                child: SingleChildScrollView(
                  child: Text(sc.state.said),
                ),
              )
            : Text("waiting for client to call ...")
          : Text("server loading ... "),
        ],
      ),
    );
  }

  void listen( BuildContext bc )
  {
    ConnectionCubit cc = BlocProvider.of<ConnectionCubit>(bc);
    ConnectionState cs = cc.state;
    SaidCubit sc = BlocProvider.of<SaidCubit>(bc);

    cs.theClient!.listen
    (
      (Uint8List data) async
      {
        final message = String.fromCharCodes(data);
        sc.update(message);
      },
      onError: (error)
      {
        print(error);
        cs.theClient!.close();
      },
    );

    cc.updateListen();
  }
}