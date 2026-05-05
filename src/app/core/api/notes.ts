import { invoke } from "@tauri-apps/api/core";
import { Note } from "../data.service";

export async function getNoteById(noteId: string, decryptContent: boolean= true): Promise<Note | null> {
  try {
    const note = await invoke<Note>("find_note_by_id", { noteId, decryptContent });
    if (note) {
      return note;
    }
  } catch (error: any) {
    console.error('Error loading note:', error);
  }
  return null;
}

export async function getNotesByGroup(groupId: string): Promise<Note[]> {
  try {
    const notes = await invoke<Note[]>("get_notes_by_group", { groupId });
    if (notes) {
      return notes;
    }
  } catch (error: any) {
    console.error('Error loading notes:', error);
  }
    return [];
}

export async function createNote(note: { title: string; content: string; is_encrypted: boolean; group_id: string }): Promise<string | null> {
  try {
    const newNoteId = await invoke<string>("add_note_in_group", { groupId: note.group_id, title: note.title, content: note.content, isEncrypted: note.is_encrypted });
    return newNoteId;
  } catch (error: any) {
    console.error('Error creating note:', error);
    return null;
  }
}

export async function deleteNote(noteId: string): Promise<boolean> {
  try {
    await invoke("delete_note", { noteId });
    return true;
  } catch (error: any) {
    console.error('Error deleting note:', error);
    return false;
  }
}

export async function updateNote(note: Note): Promise<string | null> {
  try {
    const updatedNoteId = await invoke<string>("edit_note", { noteId: note.id, title: note.title, content: note.content, isEncrypted: note.is_encrypted });
    return updatedNoteId;
  } catch (error: any) {
    console.error('Error updating note:', error);
    return null;
  }
}